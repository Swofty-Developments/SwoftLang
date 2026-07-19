open Ast
open Registry
open Tc_types

module SM = Map.Make (String)

type ventry = {
  v_ty : ty;
  v_maybe : bool;
}

type env = {
  vars : ventry SM.t;
  facts : ty SM.t;
}

type color =
  | Sync
  | Async

type fsig = {
  f_async : bool;
  f_params : (string * ty) list;
  mutable f_ret : ty;
}

type body_ctx = {
  color : color;
  event : event_def option;
  args : (string * ty) list option;
  ret_sink : (ty list ref * bool ref) option;
  (* inside an 'on packet' handler: 'cancel packet' becomes legal, and
     wait/spawn are banned in the sync section (async { } re-opens them) *)
  packet : bool;
  (* inside an api handler: the 'reply' statement becomes legal (design 6B) *)
  api : bool;
  (* inside an every/schedule/repeat body: 'stop' becomes legal and the 'run'
     counter is in scope (scheduler v2) *)
  in_schedule : bool;
}

type pinfo = {
  pi_subject : ty option;
  pi_ty : ty;
}

type ctx = {
  file : string;
  mutable errors : Diagnostics.error list;
  mutable quiet : bool;
  funcs : (string, fsig) Hashtbl.t;
  persists : (string, pinfo) Hashtbl.t;
  (* declared custom item / mob ids, for literal give/spawn/drops validation *)
  item_ids : (string, unit) Hashtbl.t;
  mob_ids : (string, unit) Hashtbl.t;
  (* declared UI / scheduler names, for reference validation of statements
     that name a declaration (show/hide scoreboard|tablist|bossbar "name",
     open/replace gui "name", cancel schedule "name"). These identifiers land
     in global runtime registries and are unique across the compilation unit,
     so every module's checker sees the whole unit's names (populated in
     Typecheck.run_all). *)
  scoreboards : (string, unit) Hashtbl.t;
  tablists : (string, unit) Hashtbl.t;
  bossbars : (string, unit) Hashtbl.t;
  holograms : (string, unit) Hashtbl.t;
  npcs : (string, unit) Hashtbl.t;
  guis : (string, unit) Hashtbl.t;
  (* named schedules: top-level 'every ... as "name"' and inline
     'schedule ... as "name"' expressions anywhere in the unit *)
  schedules : (string, unit) Hashtbl.t;
  (* module-level 'var name = expr' declarations (design 6A): private module
     state, in scope in this module's function bodies and command/event
     execute blocks *)
  mod_vars : (string, ty) Hashtbl.t;
  (* un-exported functions of directly imported modules, name -> owning
     module description, for a precise "private" error instead of a generic
     unknown-function one *)
  import_privates : (string, string) Hashtbl.t;
  (* W-viewers §2: the typed tags of the mob decl currently being checked
     (name -> declared type). Set while checking a mob{}'s handler bodies so
     mob.tags.<declared> resolves to its declared type (indexable maps/lists);
     empty everywhere else, where mob.tags.<key> stays freeform optional<Any>. *)
  mutable cur_mob_tags : (string * ty) list;
}

let err ctx (pos : pos) fmt =
  Printf.ksprintf
    (fun msg ->
      if not ctx.quiet then
        ctx.errors <-
          { Diagnostics.file = ctx.file; line = pos.line; col = pos.col; msg } :: ctx.errors)
    fmt

let warn ctx (pos : pos) fmt =
  Printf.ksprintf
    (fun msg ->
      if not ctx.quiet then
        Printf.eprintf "%s:%d:%d: warning: %s\n" ctx.file pos.line pos.col msg)
    fmt

let with_quiet ctx f =
  let old = ctx.quiet in
  ctx.quiet <- true;
  let r = f () in
  ctx.quiet <- old;
  r

(* --- suggestions --- *)

let levenshtein a b =
  let la = String.length a and lb = String.length b in
  let d = Array.make_matrix (la + 1) (lb + 1) 0 in
  for i = 0 to la do
    d.(i).(0) <- i
  done;
  for j = 0 to lb do
    d.(0).(j) <- j
  done;
  for i = 1 to la do
    for j = 1 to lb do
      let cost = if a.[i - 1] = b.[j - 1] then 0 else 1 in
      d.(i).(j) <- min (min (d.(i - 1).(j) + 1) (d.(i).(j - 1) + 1)) (d.(i - 1).(j - 1) + cost)
    done
  done;
  d.(la).(lb)

let suggestion name candidates =
  let scored =
    List.filter_map
      (fun c ->
        let dist = levenshtein name c in
        if dist <= 2 && dist < String.length name then Some (dist, c) else None)
      candidates
  in
  match List.sort compare scored with
  | (_, best) :: _ -> Printf.sprintf "; did you mean '%s'?" best
  | [] -> ""

(* --- paths and environments --- *)

let rec path_of e =
  match e.e with
  | EVar x -> Some [ x ]
  | EProp (t, n) -> (
    match path_of t with
    | Some p -> Some (p @ [ n ])
    | None -> None)
  | _ -> None

let path_key parts = String.concat "." parts

let add_facts env fs =
  { env with facts = List.fold_left (fun m (k, t) -> SM.add k t m) env.facts fs }

let invalidate_root env root =
  let prefix = root ^ "." in
  let plen = String.length prefix in
  {
    env with
    facts =
      SM.filter
        (fun k _ ->
          not (k = root || (String.length k >= plen && String.sub k 0 plen = prefix)))
        env.facts;
  }

(* a property write invalidates facts on the written path, below it, and on
   intermediate hops — but never the bare root: writing p.health cannot make
   p itself missing *)
let invalidate_path env parts =
  let full = path_key parts in
  let prefix = full ^ "." in
  let plen = String.length prefix in
  let rec mids acc cur = function
    | [] | [ _ ] -> acc
    | x :: rest ->
      let cur = cur @ [ x ] in
      let acc = if List.length cur >= 2 then path_key cur :: acc else acc in
      mids acc cur rest
  in
  let ancestors = mids [] [] parts in
  {
    env with
    facts =
      SM.filter
        (fun k _ ->
          not
            (k = full
            || (String.length k >= plen && String.sub k 0 plen = prefix)
            || List.mem k ancestors))
        env.facts;
  }

let join_env e1 e2 =
  (* fold each branch's root facts into its vars first, so presence learned
     by narrowing in one branch and by assignment in the other survives *)
  let narrowed e =
    SM.mapi
      (fun k v ->
        match SM.find_opt k e.facts with
        | Some t -> { v_ty = t; v_maybe = false }
        | None -> v)
      e.vars
  in
  let vars =
    SM.merge
      (fun _ a b ->
        match (a, b) with
        | Some x, Some y ->
          Some { v_ty = join x.v_ty y.v_ty; v_maybe = x.v_maybe || y.v_maybe }
        | Some x, None | None, Some x -> Some { x with v_maybe = true }
        | None, None -> None)
      (narrowed e1) (narrowed e2)
  in
  let facts =
    SM.merge
      (fun _ a b ->
        match (a, b) with
        | Some x, Some y when x = y -> Some x
        | _ -> None)
      e1.facts e2.facts
  in
  { vars; facts }

let bind env name ty = { env with vars = SM.add name { v_ty = ty; v_maybe = false } env.vars }

let empty_env = { vars = SM.empty; facts = SM.empty }

(* Body base environment: module-level vars are visible (and assignable,
   closure-style) inside the module's function bodies and command/event
   execute blocks *)
let base_env ctx = Hashtbl.fold (fun name ty env -> bind env name ty) ctx.mod_vars empty_env

(* possibly-missing values may not flow into places that need a concrete value *)
let require_present ctx env e t ~use =
  match e.e with
  | EVar x
    when (not (SM.mem x env.facts))
         && (match SM.find_opt x env.vars with Some v -> v.v_maybe | None -> false) ->
    err ctx e.epos
      "variable '%s' may not be assigned on all paths; assign it in every branch or check it \
       with 'if %s exists'"
      x x
  | _ -> (
    match t with
    | TOptional inner ->
      err ctx e.epos
        "%s is optional<%s> and may be missing; check it with 'if ... exists' or provide a \
         fallback with 'otherwise'"
        use (ty_to_string inner)
    | _ -> ())

let require_boolish ctx e t =
  match t with
  | TBoolean | TAny | TOptional _ -> ()
  | _ -> err ctx e.epos "condition must be a Boolean (got %s)" (ty_to_string t)

(* The parser resolves every occurrence of a declared persistent name to a
   persistent access before scoping, so a local binding (argument, parameter,
   loop variable, implicit handler binding) with the same name would be
   silently unreachable. Reject the collision instead of shadowing. *)
let check_persist_shadow ctx pos what name =
  if Hashtbl.mem ctx.persists name then
    err ctx pos "%s '%s' shadows the persistent variable '%s' — rename one of them" what name name
