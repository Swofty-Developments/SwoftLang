(* v1.10.0 §5 layer 2 — STATIC cycle detection over change handlers.

   Layer 1 (no-op suppression) kills converging cascades at runtime and layer 3
   (the propagating causality token + depth cap) catches whatever survives, but a
   handler that provably re-triggers itself is a program bug, not a runtime
   condition: it is rejected at compile time.

   The graph: one node per persistent that carries a change handler, and an edge
   n -> m whenever n's handler WRITES m — following function calls
   interprocedurally, so the write may sit several frames deep. Two shapes are
   errors:

     - a handler writing its OWN value at the SAME key: it re-fires itself
       forever, with nothing in between to converge.
     - a cycle across DIFFERENT values: coins -> leaderboard -> coins.

   The deliberate EXCEPTION (§5.2): a write to the SAME value at a DIFFERENT key
   — the `coins` handler crediting `coins for player.party_leader` — is legal.
   It is a real pattern, it is not statically provable to terminate or not, and
   the runtime depth cap already bounds it. Only same-value-SAME-key and
   cross-value cycles are static errors. *)

open Ast
open Tc_env

(* one persistent write found inside a handler (or a function it reaches).
   [w_key] is the per-ENTRY key of a collection write; None means the write
   re-stores the whole value, which touches every entry. *)
type write = {
  w_name : string;
  w_subject : expr option;
  w_key : expr option;
  w_pos : pos;
}

(* the compiler's own per-key spellings re-store the whole row over a
   map_set/map_delete of the value; recover the key they target so a write to a
   DIFFERENT entry is not mistaken for a whole-value re-store. *)
let per_key_of name (v : expr) =
  match v.e with
  | ECall (("map_set" | "map_delete"), coll :: key :: _) -> (
    match coll.e with EPersistGet (n, _) when n = name -> Some key | _ -> None)
  | _ -> None

(* every persistent write reachable from [body], following calls through
   [find_fn]. A function is followed once — recursion terminates and a repeated
   call contributes no new edges. *)
let writes_reachable ~find_fn body =
  let acc = ref [] in
  let seen = Hashtbl.create 8 in
  let rec go body =
    Walk.iter_stmts
      ~on_expr:(fun (e : expr) ->
        match e.e with ECall (n, _) | EFutureSpawn (n, _) -> follow n | _ -> ())
      ~on_stmt:(fun (s : stmt) ->
        match s.s with
        | SPersistSet (name, subject, value) ->
          acc :=
            { w_name = name; w_subject = subject; w_key = per_key_of name value; w_pos = s.spos }
            :: !acc
        | SPersistAtomic pa ->
          acc :=
            { w_name = pa.pa_name; w_subject = pa.pa_subject; w_key = pa.pa_key;
              w_pos = pa.pa_pos }
            :: !acc
        | SCall (n, _) | SSpawn (n, _) -> follow n
        | _ -> ())
      body
  and follow n =
    if not (Hashtbl.mem seen n) then begin
      Hashtbl.replace seen n ();
      match find_fn n with Some (f : func) -> go f.body | None -> ()
    end
  in
  go body;
  List.rev !acc

let bare_name expected (e : expr) = match e.e with EVar v -> v = expected | _ -> false

(* does [w] write the handler's OWN value at the key the handler is firing for?
   That is the shape with no escape: the write re-enters the same handler with
   the same key. A different key is the §5.2 exception and stays legal. *)
let hits_own_key (pd : persistent_decl) (pc : persist_change) (w : write) =
  let same_subject =
    match (persist_subject_bind pd, w.w_subject) with
    (* a global has exactly one slot *)
    | None, _ -> true
    (* the handler's own key, written back verbatim *)
    | Some b, Some se -> bare_name b se
    (* a keyed decl written with no key at all is a checker error already *)
    | Some _, None -> true
  in
  same_subject
  &&
  match pc.pc_kind with
  | PCScalar -> true
  | PCEntry -> (
    (* a per-entry write only re-enters at the SAME entry; a whole-collection
       re-store (no key) touches every entry, this one included *)
    match w.w_key with None -> true | Some ke -> bare_name "key" ke)

type node = {
  n_name : string;
  n_ctx : ctx;
  n_decl : persistent_decl;
  n_change : persist_change;
  mutable n_edges : string list; (* other change-handling values this one writes *)
}

(* [units] pairs each module's checker context and script with the function
   lookup that module sees (its own functions plus what it imported), so an
   interprocedural write is followed exactly the way the program resolves it. *)
let check (units : (ctx * Ast.script * (string -> Ast.func option)) list) =
  let nodes = ref [] in
  List.iter
    (fun (ctx, (script : Ast.script), _) ->
      List.iter
        (fun (pd : persistent_decl) ->
          match pd.pd_change with
          | None -> ()
          | Some pc ->
            nodes :=
              { n_name = pd.pd_name; n_ctx = ctx; n_decl = pd; n_change = pc; n_edges = [] }
              :: !nodes)
        script.persistents)
    units;
  let nodes = List.rev !nodes in
  if nodes <> [] then begin
    let by_name = Hashtbl.create 8 in
    List.iter (fun n -> Hashtbl.replace by_name n.n_name n) nodes;
    let find_unit ctx =
      List.find_opt (fun (c, _, _) -> c == ctx) units
    in
    List.iter
      (fun n ->
        let find_fn =
          match find_unit n.n_ctx with Some (_, _, f) -> f | None -> fun _ -> None
        in
        let writes = writes_reachable ~find_fn n.n_change.pc_body in
        let edges = ref [] in
        List.iter
          (fun w ->
            if w.w_name = n.n_name then begin
              if hits_own_key n.n_decl n.n_change w then
                err n.n_ctx w.w_pos
                  "the '%s' for '%s' writes '%s', which would re-fire itself forever"
                  (persist_change_kw n.n_change.pc_kind)
                  n.n_name n.n_name
              (* else: the §5.2 exception — same value, different key. Legal; the
                 runtime depth cap is what bounds it. *)
            end
            else if Hashtbl.mem by_name w.w_name && not (List.mem w.w_name !edges) then
              edges := w.w_name :: !edges)
          writes;
        n.n_edges <- List.rev !edges)
      nodes;
    (* shortest cycle through [start], BFS so the reported path is the smallest
       one the programmer has to break *)
    let succs name =
      match Hashtbl.find_opt by_name name with Some n -> n.n_edges | None -> []
    in
    let find_cycle start =
      let prev = Hashtbl.create 16 in
      let q = Queue.create () in
      List.iter
        (fun m ->
          if not (Hashtbl.mem prev m) then begin
            Hashtbl.replace prev m start;
            Queue.add m q
          end)
        (succs start);
      let found = ref false in
      while (not !found) && not (Queue.is_empty q) do
        let v = Queue.pop q in
        if v = start then found := true
        else
          List.iter
            (fun w ->
              if not (Hashtbl.mem prev w) then begin
                Hashtbl.replace prev w v;
                Queue.add w q
              end)
            (succs v)
      done;
      if not !found then None
      else begin
        let rec build cur acc =
          let p = Hashtbl.find prev cur in
          if p = start then start :: acc else build p (p :: acc)
        in
        Some (build start [ start ])
      end
    in
    let reported = Hashtbl.create 8 in
    List.iter
      (fun n ->
        if not (Hashtbl.mem reported n.n_name) then
          match find_cycle n.n_name with
          | None -> ()
          | Some path ->
            List.iter (fun m -> Hashtbl.replace reported m ()) path;
            err n.n_ctx n.n_change.pc_pos "change handlers form a cycle: %s"
              (String.concat " -> " path))
      nodes
  end
