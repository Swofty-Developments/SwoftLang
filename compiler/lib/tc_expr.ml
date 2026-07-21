open Ast
open Registry
open Tc_types
open Tc_env

let interp_paths s =
  let out = ref [] in
  let n = String.length s in
  let i = ref 0 in
  while !i < n - 1 do
    if s.[!i] = '$' && s.[!i + 1] = '{' then (
      match String.index_from_opt s (!i + 2) '}' with
      | Some j ->
        out := String.sub s (!i + 2) (j - !i - 2) :: !out;
        i := j + 1
      | None -> i := n)
    else incr i
  done;
  List.rev !out

let is_simple_path frag =
  let parts = String.split_on_char '.' frag in
  parts <> []
  && List.for_all
       (fun part ->
         String.length part > 0
         && (match part.[0] with 'a' .. 'z' | 'A' .. 'Z' | '_' -> true | _ -> false)
         && String.for_all
              (function 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> true | _ -> false)
              part)
       parts

(* installed by Tc_stmt at load time: lambda bodies are statement lists, and
   statement checking lives above this module *)
let check_stmts_ref : (ctx -> body_ctx -> env -> stmt list -> env * bool) ref =
  ref (fun _ _ env _ -> (env, false))

(* the type a call through `name` would see, without the unknown-variable
   error var_type raises: callers fall back to functions/builtins *)
let callee_var_type env name =
  match SM.find_opt name env.facts with
  | Some t -> Some t
  | None -> (
    match SM.find_opt name env.vars with
    | Some v -> Some (if v.v_maybe then wrap_optional v.v_ty else v.v_ty)
    | None -> None)

let not_a_function ctx pos name t =
  let s = ty_to_string t in
  let article =
    match s.[0] with 'A' | 'E' | 'I' | 'O' | 'U' | 'a' | 'e' | 'i' | 'o' | 'u' -> "an" | _ -> "a"
  in
  err ctx pos "'%s' is %s %s, not a function" name article s

let rec type_of ctx bctx env e : ty =
  match e.e with
  | EString s ->
    check_interpolation ctx bctx env e.epos s;
    TString
  | ENumber { integer; _ } -> if integer then TInteger else TDouble
  | EBool _ -> TBoolean
  | ENone -> TOptional TAny
  | EType name ->
    if not (List.mem name known_type_names) then
      warn ctx e.epos "unknown type '%s' in 'is a' check" name;
    TAny
  | EVar name -> var_type ctx bctx env e.epos name
  | EProp (target, name) -> prop_type ctx bctx env e target name
  | EPersistGet (name, subject) -> (
    (* persistent reads are total: a missing row yields the declared default,
       so the type is the declared type, never optional *)
    match Hashtbl.find_opt ctx.persists name with
    | Some pi ->
      check_persist_subject ctx bctx env e.epos name pi subject;
      pi.pi_ty
    | None ->
      (* parser only emits persist_get for declared names; defensive *)
      err ctx e.epos "unknown persistent '%s'" name;
      TAny)
  | EAllPlayers -> TList TPlayer
  | EList items ->
    let ts = List.map (fun it -> type_of ctx bctx env it) items in
    let elem = match ts with [] -> TAny | t :: rest -> List.fold_left join t rest in
    TList elem
  | ECall (name, args) -> call_type ctx bctx env e.epos name args
  | EMethod (recv, name, args) ->
    check_method ctx bctx env e.epos recv name args ~as_stmt:false
  | ELambda { lam_async; lam_params; lam_body } ->
    lambda_type ctx bctx env lam_async lam_params lam_body
  | EMap entries ->
    (* packet field maps are shape-opaque: values typecheck, the map is Any.
       A literal 'none' is legal — it is the design-5D spelling of a null
       packet component (e.g. a missing chatSession) *)
    List.iter
      (fun (_, v) ->
        let vt = type_of ctx bctx env v in
        match v.e with
        | ENone -> ()
        | _ -> require_present ctx env v vt ~use:"the packet field value")
      entries;
    TAny
  | EMapLit entries ->
    (* map<K, V> literal: K is inferred from the keys (all String -> String, all
       Integer -> Integer; mixing them is an error). V is the join of the value
       types. Values must be present — a map cannot store a possibly-missing
       value directly. *)
    let has_str = List.exists (fun (k, _) -> match k with MKStr _ -> true | _ -> false) entries in
    let has_int = List.exists (fun (k, _) -> match k with MKInt _ -> true | _ -> false) entries in
    let kty =
      if has_str && has_int then begin
        err ctx e.epos "map keys must all be String or all Integer";
        TAny
      end
      else if has_int then TInteger
      else TString
    in
    let vts =
      List.map
        (fun (_, v) ->
          let vt = type_of ctx bctx env v in
          require_present ctx env v vt ~use:"a map literal value";
          vt)
        entries
    in
    let elem = match vts with [] -> TAny | t :: rest -> List.fold_left join t rest in
    TMap (kty, elem)
  | ELoaderStorage _ ->
    (* backend config is literal syntax, validated by the parser *)
    TWorldLoader
  | ESchedule { sc_after; sc_every; sc_name = _; sc_body } ->
    (match sc_after with
    | Some n when n <= 0 -> err ctx e.epos "schedule delay must be positive"
    | _ -> ());
    (match sc_every with
    | Some n when n <= 0 -> err ctx e.epos "schedule cadence must be positive"
    | _ -> ());
    (* like a lambda body: it runs later on the AsyncRuntime against a
       snapshot of the variables, so narrowing facts are dropped and the
       body is async-colored. 'stop' is legal and the 1-based 'run' counter
       is in scope (scheduler v2) *)
    let bctx' = { bctx with color = Async; ret_sink = None; in_schedule = true; override = None } in
    let env' = bind { env with facts = SM.empty } "run" TInteger in
    ignore (!check_stmts_ref ctx bctx' env' sc_body);
    TSchedule
  | ETaskRunning { tr_owner; tr_id = _ } ->
    (* '<obj>.tasks.<id> is running' — the owner must carry a .tasks registry
       (Player/Mob/Entity/Display/Block); result is a Boolean *)
    let ot = type_of ctx bctx env tr_owner in
    require_present ctx env tr_owner ot ~use:"the task owner";
    (match unwrap ot with
    | t when is_task_owner t -> ()
    | TItem ->
      err ctx tr_owner.epos
        "Item has no task registry; .tasks is only available on Player, Mob, Entity, Npc, \
         Hologram, and block_at(...) (items are value types with no stable identity)"
    | t ->
      err ctx tr_owner.epos "%s has no task registry; .tasks needs a Player, Mob, Entity, Display, or Block owner"
        (ty_to_string t));
    TBoolean
  | EUnary ("NOT", x) ->
    let t = type_of ctx bctx env x in
    require_present ctx env x t ~use:"the operand of 'not'";
    if not (boolish t) then
      err ctx x.epos "'not' requires a Boolean operand (got %s)" (ty_to_string t);
    TBoolean
  | EUnary ("NEGATE", x) ->
    let t = type_of ctx bctx env x in
    require_present ctx env x t ~use:"the negated value";
    if not (num_ok t) then err ctx x.epos "unary '-' requires a number (got %s)" (ty_to_string t);
    num_join t t
  | EUnary ("EXISTS", x) ->
    ignore (type_of ctx bctx env x);
    TBoolean
  | EUnary (_, x) ->
    ignore (type_of ctx bctx env x);
    TAny
  | EBinary (op, l, r) -> binary_type ctx bctx env e.epos op l r

and var_type ctx bctx env pos name =
  match SM.find_opt name env.facts with
  | Some t -> t
  | None -> (
    match SM.find_opt name env.vars with
    | Some v -> if v.v_maybe then wrap_optional v.v_ty else v.v_ty
    | None ->
      if name = "args" && bctx.args <> None then TAny
        (* 'server' is an implicit global value (design 6B TPS / 6D MOTD);
           a local binding of the same name shadows it *)
      else if name = "server" then TServer
      else begin
        let candidates = SM.fold (fun k _ acc -> k :: acc) env.vars [] in
        err ctx pos "variable '%s' is never assigned%s" name (suggestion name candidates);
        TAny
      end)

and prop_type ctx bctx env whole target name =
  let fact =
    match path_of whole with
    | Some p -> SM.find_opt (path_key p) env.facts
    | None -> None
  in
  match fact with
  | Some t -> t
  | None -> (
    match (target.e, bctx.args) with
    | EVar "args", Some args when not (SM.mem "args" env.vars) -> (
      match List.assoc_opt name args with
      | Some t -> t
      | None ->
        err ctx whole.epos "unknown argument '%s'%s" name
          (suggestion name (List.map fst args));
        TAny)
    (* `packet.<field>` inside a Packet handler: type the field against the
       resolved packet class's catalog. An unknown field errors with the valid
       set (mirroring block/property validation). The handler forbids user
       rebinding of `packet`, so this fires whenever we are in a Packet body. *)
    | EVar "packet", _ when ctx.cur_packet_fields <> None -> (
      let cls, fields =
        match ctx.cur_packet_fields with Some (c, f) -> (c, f) | None -> ("", [])
      in
      match List.assoc_opt name fields with
      | Some t -> t
      | None ->
        err ctx whole.epos "unknown field '%s' on packet %s%s" name cls
          (suggestion name (List.map fst fields));
        TAny)
    | _ when inside_tags ctx bctx env target ->
      (* item.tags.<path...>: a tag namespace is freely traversable — an
         intermediate compound node (item.tags.meta) is itself optional<Any>
         but descending into it must not force a presence check. The leaf read
         stays optional<Any> so the no-null discipline still applies to it. *)
      TOptional TAny
    | _ ->
      let tt = type_of ctx bctx env target in
      require_present ctx env target tt ~use:"this value";
      let owner = unwrap tt in
      (match owner with
      | TAny -> TAny
      | TEither ts ->
        err ctx whole.epos
          "cannot access property '%s' on either<%s>; narrow it first with 'is a'" name
          (String.concat "|" (List.map ty_to_string ts));
        TAny
      (* W-viewers §2: a declared typed tag of the current mob resolves to its
         declared type (an indexable map/list), so mob.tags.hits[k] typechecks
         against map<K, V>. Undeclared keys fall through to the freeform
         optional<Any> tag namespace below. *)
      | TEntityTags when List.mem_assoc name ctx.cur_mob_tags ->
        List.assoc name ctx.cur_mob_tags
      | _ -> (
        match props_of_ty owner with
        | None ->
          err ctx whole.epos "%s has no property '%s'" (ty_to_string owner) name;
          TAny
        | Some props -> (
          match find_prop owner name with
          | Some p -> p.p_ty
          | None ->
            err ctx whole.epos "unknown property '%s' on %s%s" name (ty_to_string owner)
              (suggestion name (List.map (fun p -> p.p_name) props));
            TAny))))

(* true when `e` names a node inside an item.tags.* namespace, i.e. an EProp
   whose base resolves to TItemTags (a direct `.tags`) or is itself such a
   node. Lets nested tag paths (item.tags.meta.tier) traverse compound levels
   without a presence check at each step (phase 9 §2). Base types are probed
   quietly so the detection never emits its own diagnostics. *)
and inside_tags ctx bctx env e =
  match e.e with
  | EProp (base, _) -> (
    match with_quiet ctx (fun () -> type_of ctx bctx env base) with
    | t when is_tags_ty t -> true
    | _ -> inside_tags ctx bctx env base)
  | _ -> false

and binary_type ctx bctx env pos op l r =
  match op with
  | "ADD" ->
    let lt = type_of ctx bctx env l in
    let rt = type_of ctx bctx env r in
    require_present ctx env l lt ~use:"the left operand of '+'";
    require_present ctx env r rt ~use:"the right operand of '+'";
    if num_ok lt && num_ok rt then num_join lt rt else TString
  | "SUBTRACT" | "MULTIPLY" | "DIVIDE" | "MODULO" ->
    let lt = type_of ctx bctx env l in
    let rt = type_of ctx bctx env r in
    require_present ctx env l lt ~use:"the left operand";
    require_present ctx env r rt ~use:"the right operand";
    if not (num_ok lt) then
      err ctx l.epos "arithmetic requires numbers (got %s)" (ty_to_string lt);
    if not (num_ok rt) then
      err ctx r.epos "arithmetic requires numbers (got %s)" (ty_to_string rt);
    num_join lt rt
  | "LESS_THAN" | "GREATER_THAN" | "LESS_EQUALS" | "GREATER_EQUALS" ->
    let lt = type_of ctx bctx env l in
    let rt = type_of ctx bctx env r in
    require_present ctx env l lt ~use:"the left operand";
    require_present ctx env r rt ~use:"the right operand";
    let kind = function
      | TInteger | TDouble -> `Num
      | TString -> `Str
      | TAny -> `Any
      | _ -> `Bad
    in
    (match kind lt with
    | `Bad -> err ctx l.epos "cannot order values of type %s" (ty_to_string lt)
    | _ -> ());
    (match kind rt with
    | `Bad -> err ctx r.epos "cannot order values of type %s" (ty_to_string rt)
    | _ -> ());
    (match (kind lt, kind rt) with
    | `Num, `Str | `Str, `Num ->
      err ctx pos "cannot compare %s with %s" (ty_to_string lt) (ty_to_string rt)
    | _ -> ());
    TBoolean
  | "EQUALS" | "NOT_EQUALS" ->
    ignore (type_of ctx bctx env l);
    ignore (type_of ctx bctx env r);
    TBoolean
  | "AND" | "OR" ->
    let lt = type_of ctx bctx env l in
    require_present ctx env l lt ~use:"the left operand";
    if not (boolish lt) then
      err ctx l.epos "'%s' requires Boolean operands (got %s)" (String.lowercase_ascii op)
        (ty_to_string lt);
    (* short-circuit: the right operand sees the left's narrowing *)
    let lft, lfe = cond_facts ctx bctx env l in
    let renv = add_facts env (if op = "AND" then lft else lfe) in
    let rt = type_of ctx bctx renv r in
    require_present ctx renv r rt ~use:"the right operand";
    if not (boolish rt) then
      err ctx r.epos "'%s' requires Boolean operands (got %s)" (String.lowercase_ascii op)
        (ty_to_string rt);
    TBoolean
  | "CONTAINS" ->
    let lt = type_of ctx bctx env l in
    let rt = type_of ctx bctx env r in
    require_present ctx env l lt ~use:"the left operand of 'contains'";
    require_present ctx env r rt ~use:"the right operand of 'contains'";
    TBoolean
  | "IS_TYPE" | "IS_NOT_TYPE" ->
    ignore (type_of ctx bctx env l);
    ignore (type_of ctx bctx env r);
    TBoolean
  | "CONCATENATE" ->
    (* desugared interpolation fragment: checked as an expression, with the
       same maybe-assigned guard the plain interpolation checker applies *)
    List.iter
      (fun x ->
        ignore (type_of ctx bctx env x);
        match x.e with
        | EVar v
          when (not (SM.mem v env.facts))
               && (match SM.find_opt v env.vars with Some e -> e.v_maybe | None -> false) ->
          err ctx x.epos
            "variable '%s' may not be assigned on all paths; assign it in every branch or \
             check it with 'if %s exists'"
            v v
        | _ -> ())
      [ l; r ];
    TString
  | "OR_ELSE" ->
    let lt = type_of ctx bctx env l in
    let rt = type_of ctx bctx env r in
    join (unwrap lt) rt
  | _ ->
    ignore (type_of ctx bctx env l);
    ignore (type_of ctx bctx env r);
    TAny

and check_call_args ctx bctx env pos name ptys args =
  let expected = List.length ptys in
  let got = List.length args in
  if got <> expected then begin
    err ctx pos "function '%s' expects %d argument(s), got %d" name expected got;
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args
  end
  else
    List.iteri
      (fun i a ->
        let pty = List.nth ptys i in
        let at = type_of ctx bctx env a in
        (match pty with
        | TOptional _ -> ()
        | _ -> require_present ctx env a at ~use:(Printf.sprintf "argument %d of '%s'" (i + 1) name));
        if not (param_compat pty at) then
          err ctx a.epos "argument %d of '%s' expects %s, got %s" (i + 1) name
            (ty_to_string pty) (ty_to_string at))
      args

(* lambda values: the body checks against the defining environment with all
   narrowing facts dropped — the body may run long after definition, so
   captured mutable state reverts to its declared/widened type *)
and lambda_type ctx bctx env lam_async lam_params lam_body =
  List.iter
    (fun (p : Ast.param) -> check_persist_shadow ctx p.p_pos "parameter" p.p_name)
    lam_params;
  let params =
    List.map
      (fun (p : Ast.param) ->
        (p.p_name, match p.p_type with Some dt -> ty_of_dt dt | None -> TAny))
      lam_params
  in
  let benv =
    List.fold_left
      (fun env (name, ty) -> bind env name ty)
      { env with facts = SM.empty }
      params
  in
  let vals = ref [] in
  let bare = ref false in
  let bctx' =
    { bctx with color = (if lam_async then Async else Sync); ret_sink = Some (vals, bare) }
  in
  let _, terminates = !check_stmts_ref ctx bctx' benv lam_body in
  let ret =
    match !vals with
    | [] -> TAny
    | t :: rest ->
      let joined = List.fold_left join t rest in
      if !bare || not terminates then wrap_optional joined else joined
  in
  TFunction { fn_async = lam_async; fn_params = List.map snd params; fn_ret = ret }

(* resolution order: a local variable holding a callable, then declared
   functions, then builtins *)
and call_type ctx bctx env pos name args =
  if name = "default" then begin
    (* default() re-runs the base receiver method this handler overrides, with
       the same `this`/args; legal only inside an overriding custom-decl method *)
    (match bctx.override with
    | None ->
      err ctx pos
        "'default()' is only valid inside a custom declaration method that overrides a base \
         receiver method"
    | Some _ ->
      if args <> [] then
        err ctx pos
          "'default()' takes no arguments; it re-invokes the base method with the same arguments");
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
    TAny
  end
  else
  let looked = callee_var_type env name in
  match looked with
  | Some (TFunction f) ->
    check_call_args ctx bctx env pos name f.fn_params args;
    if f.fn_async && bctx.color = Sync then
      err ctx pos
        "'%s' is an async function; call it with 'spawn %s(...)' or move this call into an \
         async context"
        name name;
    f.fn_ret
  | Some TAny | Some (TOptional TAny) ->
    (* dynamically-typed callee: nothing to check statically *)
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
    TAny
  | Some (TOptional (TFunction _)) ->
    err ctx pos "'%s' may be missing; check it with 'if %s exists' before calling it" name name;
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
    TAny
  | _ -> (
    match Hashtbl.find_opt ctx.funcs name with
    | Some f ->
      check_call_args ctx bctx env pos name (List.map snd f.f_params) args;
      if f.f_async && bctx.color = Sync then
        err ctx pos
          "'%s' is an async function; call it with 'spawn %s(...)' or move this call into an \
           async context"
          name name;
      f.f_ret
    | None -> builtin_call_type ctx bctx env pos name args looked)

(* map builtins whose result type depends on the map's value type V; the
   registry table lists them only so name-collision checks see them (phase 10) *)
and map_builtin_type ctx bctx env pos name args =
  let arity =
    match name with
    | "map_keys" | "map_size" -> 1
    | "map_set" -> 3
    | _ -> 2
  in
  let got = List.length args in
  if got <> arity then begin
    err ctx pos "'%s' expects %d argument(s), got %d" name arity got;
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
    TAny
  end
  else begin
    let map_arg = List.hd args in
    let mt = type_of ctx bctx env map_arg in
    require_present ctx env map_arg mt ~use:(Printf.sprintf "the map argument of '%s'" name);
    let kty, velem =
      match unwrap mt with
      | TMap (k, v) -> (k, v)
      | TAny -> (TAny, TAny)
      | _ ->
        err ctx map_arg.epos "'%s' expects a map here, got %s" name (ty_to_string mt);
        (TAny, TAny)
    in
    (* the key argument (arg 2, when present) must match the map's key type K *)
    (match args with
    | _ :: key :: _ when arity >= 2 ->
      let kt = type_of ctx bctx env key in
      require_present ctx env key kt ~use:(Printf.sprintf "the key argument of '%s'" name);
      if not (param_compat kty kt) then
        err ctx key.epos "'%s' expects a %s key here (got %s)" name (ty_to_string kty)
          (ty_to_string kt)
    | _ -> ());
    (* the value argument of map_set must be present and compatible with V *)
    (match (name, args) with
    | "map_set", [ _; _; v ] ->
      let vt = type_of ctx bctx env v in
      require_present ctx env v vt ~use:"the value argument of 'map_set'";
      if not (param_compat velem vt) then
        err ctx v.epos "'map_set' expects a %s value (got %s)" (ty_to_string velem)
          (ty_to_string vt)
    | _ -> ());
    match name with
    | "map_get" -> wrap_optional velem
    | "map_has" -> TBoolean
    | "map_keys" -> TList kty
    | "map_size" -> TInteger
    | "map_set" | "map_delete" -> TAny
    | _ -> TAny
  end

(* a key lambda for sort_by/min_by/max_by/sort_map_by: a function of the given
   arity returning a comparable (Number or String) key. Validated when the
   callee's type is statically a function (phase 11). *)
and check_key_lambda ctx bctx env name lam ~arity =
  let lt = type_of ctx bctx env lam in
  match lt with
  | TFunction f ->
    if List.length f.fn_params <> arity then
      err ctx lam.epos "the key function of '%s' must take %d argument(s), got %d" name arity
        (List.length f.fn_params);
    (match unwrap f.fn_ret with
    | TInteger | TDouble | TString | TAny -> ()
    | other ->
      err ctx lam.epos "the key function of '%s' must return a Number or String (got %s)" name
        (ty_to_string other))
  | TAny -> ()
  | _ -> err ctx lam.epos "'%s' expects a function as its key here, got %s" name (ty_to_string lt)

and list_elem_of ctx pos name mt =
  match unwrap mt with
  | TList t -> t
  | TAny -> TAny
  | _ ->
    err ctx pos "'%s' expects a list here, got %s" name (ty_to_string mt);
    TAny

and map_type_of ctx pos name mt =
  match unwrap mt with
  | TMap (k, v) -> (k, v)
  | TAny -> (TAny, TAny)
  | _ ->
    err ctx pos "'%s' expects a map here, got %s" name (ty_to_string mt);
    (TAny, TAny)

(* sorting/shuffle/random_in builtins whose result type flows from the
   collection element type (or the map key/value types); handled specially so
   list<T> in yields list<T>/optional<T> out and a map returns the same map
   type (phase 11) *)
and collection_builtin_type ctx bctx env pos name args =
  let check_arity n =
    let got = List.length args in
    if got <> n then begin
      err ctx pos "'%s' expects %d argument(s), got %d" name n got;
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
      false
    end
    else true
  in
  match name with
  | "sort" | "reverse" | "shuffle" ->
    if not (check_arity 1) then TList TAny
    else begin
      let a = List.hd args in
      let mt = type_of ctx bctx env a in
      require_present ctx env a mt ~use:(Printf.sprintf "the list argument of '%s'" name);
      TList (list_elem_of ctx a.epos name mt)
    end
  | "random_in" | "random_element" ->
    if not (check_arity 1) then wrap_optional TAny
    else begin
      let a = List.hd args in
      let mt = type_of ctx bctx env a in
      require_present ctx env a mt ~use:(Printf.sprintf "the list argument of '%s'" name);
      wrap_optional (list_elem_of ctx a.epos name mt)
    end
  (* W-stdlib B3: sum/product over list<Number>. Result is Integer for an
     Integer list, otherwise Double (Number join). *)
  | "sum" | "product" ->
    if not (check_arity 1) then TDouble
    else begin
      let a = List.hd args in
      let mt = type_of ctx bctx env a in
      require_present ctx env a mt ~use:(Printf.sprintf "the list argument of '%s'" name);
      let elem = list_elem_of ctx a.epos name mt in
      (match elem with
      | TInteger -> TInteger
      | TDouble | TAny -> TDouble
      | _ ->
        err ctx a.epos "'%s' expects a list of numbers (got list<%s>)" name (ty_to_string elem);
        TDouble)
    end
  | "sort_by" | "sort_by_desc" | "min_by" | "max_by" ->
    let empty () = if name = "min_by" || name = "max_by" then wrap_optional TAny else TList TAny in
    if not (check_arity 2) then empty ()
    else begin
      let a = List.nth args 0 in
      let lam = List.nth args 1 in
      let mt = type_of ctx bctx env a in
      require_present ctx env a mt ~use:(Printf.sprintf "the list argument of '%s'" name);
      let elem = list_elem_of ctx a.epos name mt in
      check_key_lambda ctx bctx env name lam ~arity:1;
      if name = "min_by" || name = "max_by" then wrap_optional elem else TList elem
    end
  | "sort_by_key" | "sort_by_key_desc" | "sort_by_value" | "sort_by_value_desc" ->
    if not (check_arity 1) then TMap (TAny, TAny)
    else begin
      let a = List.hd args in
      let mt = type_of ctx bctx env a in
      require_present ctx env a mt ~use:(Printf.sprintf "the map argument of '%s'" name);
      let k, v = map_type_of ctx a.epos name mt in
      (match name with
      | "sort_by_value" | "sort_by_value_desc" -> (
        match v with
        | TInteger | TDouble | TString | TAny -> ()
        | _ ->
          err ctx a.epos "'%s' needs a map with Number or String values (got map values of %s)"
            name (ty_to_string v))
      | _ -> ());
      TMap (k, v)
    end
  | "sort_map_by" | "sort_map_by_desc" ->
    if not (check_arity 2) then TMap (TAny, TAny)
    else begin
      let a = List.nth args 0 in
      let lam = List.nth args 1 in
      let mt = type_of ctx bctx env a in
      require_present ctx env a mt ~use:(Printf.sprintf "the map argument of '%s'" name);
      let k, v = map_type_of ctx a.epos name mt in
      check_key_lambda ctx bctx env name lam ~arity:2;
      TMap (k, v)
    end
  | _ -> TAny

and builtin_call_type ctx bctx env pos name args looked =
  match name with
  (* W-viewers: 'viewers of <entity>' -> list<Player> (getViewers) *)
  | "viewers_of" ->
    (match args with
    | [ a ] ->
      let t = type_of ctx bctx env a in
      require_present ctx env a t ~use:"the entity in 'viewers of'";
      (match unwrap t with
      | TEntity | TMob | TAny -> ()
      | _ ->
        err ctx a.epos "'viewers of' expects an Entity or Mob (got %s)" (ty_to_string t))
    | _ ->
      err ctx pos "'viewers of' expects a single entity";
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args);
    TList TPlayer
  (* W-viewers §2: 'viewers of npc "n"' -> list<Player>. Name-keyed: the npc
     name must resolve to a declared npc (unknown => error + suggestion). *)
  | "viewers_of_npc" ->
    (match args with
    | [ { e = EString name; _ } ] ->
      if not (Hashtbl.mem ctx.npcs name) then
        err ctx pos "unknown npc '%s'; declare it with 'npc \"%s\" { }'%s" name name
          (suggestion name (Hashtbl.fold (fun k _ acc -> k :: acc) ctx.npcs []))
    | _ -> err ctx pos "'viewers of npc' expects a literal npc name");
    TList TPlayer
  (* W-blocks: block("id") / block("id", { prop: value, ... }) -> Block. The
     property map is an ident-keyed brace (EMap). Literal ids/props/values are
     validated against the block-state schema; dynamic args are runtime-checked. *)
  | "block" ->
    let check_id id =
      Tc_registry_checks.check_block_id_literal ctx id ~where:"block(...)";
      let it = type_of ctx bctx env id in
      require_present ctx env id it ~use:"the block id";
      (match it with
      | TString | TAny -> ()
      | _ -> err ctx id.epos "block(...) expects a String id (got %s)" (ty_to_string it))
    in
    (match args with
    | [ id ] ->
      check_id id;
      TBlock
    | [ id; props ] ->
      check_id id;
      let id_opt = Tc_registry_checks.block_literal_id id in
      (match props.e with
      | EMap entries ->
        List.iter
          (fun (k, v) ->
            let vt = type_of ctx bctx env v in
            require_present ctx env v vt ~use:"a block property value";
            (match vt with
            | TString | TAny -> ()
            | _ -> err ctx v.epos "block property '%s' must be a String value (got %s)" k
                     (ty_to_string vt));
            match id_opt with
            | Some bid ->
              let value =
                match Tc_registry_checks.literal_string v with
                | Some s -> Some (s, v.epos)
                | None -> None
              in
              Tc_registry_checks.check_block_prop ctx ~id:bid ~name:k ~name_pos:v.epos ~value
            | None -> ())
          entries
      | _ ->
        err ctx props.epos "block(...) properties must be a '{ prop: value }' map";
        ignore (type_of ctx bctx env props));
      TBlock
    | _ ->
      err ctx pos "'block' expects 1 or 2 arguments, got %d" (List.length args);
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
      TBlock)
  | "map_get" | "map_set" | "map_has" | "map_delete" | "map_keys" | "map_size" ->
    map_builtin_type ctx bctx env pos name args
  | "sort" | "sort_by" | "sort_by_desc" | "reverse" | "shuffle" | "random_in" | "min_by"
  | "max_by" | "sort_by_key" | "sort_by_key_desc" | "sort_by_value" | "sort_by_value_desc"
  | "sort_map_by" | "sort_map_by_desc" | "random_element" | "sum" | "product" ->
    ignore looked;
    collection_builtin_type ctx bctx env pos name args
  (* W-stdlib B6: type_of accepts a value of any type and names it *)
  | "type_of" ->
    (match args with
    | [ a ] -> ignore (type_of ctx bctx env a)
    | _ ->
      err ctx pos "'type_of' expects 1 argument, got %d" (List.length args);
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args);
    TString
  (* W-stdlib B7: location_of accepts any live entity (Player/Mob/Entity/Display) *)
  | "location_of" ->
    (match args with
    | [ a ] ->
      let t = type_of ctx bctx env a in
      require_present ctx env a t ~use:"the entity of 'location_of'";
      (match unwrap t with
      | TPlayer | TMob | TEntity | TDisplay | TOfflinePlayer | TAny -> ()
      | _ -> err ctx a.epos "'location_of' expects an entity (got %s)" (ty_to_string t))
    | _ ->
      err ctx pos "'location_of' expects 1 argument, got %d" (List.length args);
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args);
    TLocation
  (* W-stdlib B1: parse(s, Type) -> optional<Type>. The second argument is a
     type name (String, Integer, Double, Boolean, ...), not a value. *)
  | "parse" ->
    (match args with
    | [ s; targ ] ->
      let st = type_of ctx bctx env s in
      require_present ctx env s st ~use:"the string of 'parse'";
      (match st with
      | TString | TAny -> ()
      | _ -> err ctx s.epos "'parse' expects a String to parse (got %s)" (ty_to_string st));
      (match targ.e with
      | EVar tn -> (
        match Tc_types.ty_of_type_name tn with
        | Some t -> wrap_optional t
        | None ->
          err ctx targ.epos
            "'parse' expects a type name as its second argument (String, Integer, Double, \
             Boolean, ...), got '%s'"
            tn;
          wrap_optional TAny)
      | _ ->
        err ctx targ.epos
          "'parse' expects a type name as its second argument (e.g. Integer), not a value";
        wrap_optional TAny)
    | _ ->
      err ctx pos "'parse' expects 2 arguments (a String and a type name), got %d"
        (List.length args);
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
      wrap_optional TAny)
  | _ -> (
    match find_builtin name with
    | Some b ->
    (* literal id arguments of the content builtins resolve at compile time *)
    (match (name, args) with
    | "custom_item", [ a ] ->
      Tc_registry_checks.check_item_id_literal ctx a ~allow_vanilla:false
        ~where:"custom_item(...)"
    | "all_mobs", [ a ] -> Tc_registry_checks.check_mob_id_literal ctx a ~where:"all_mobs(...)"
    | "all_entities", [ a ] ->
      Tc_registry_checks.check_entity_type_literal ctx a ~where:"all_entities(...)"
    | "is_running", [ a ] ->
      Tc_registry_checks.check_schedule_name_literal ctx a ~where:"is_running(...)"
    | _ -> ());
    if b.b_async_only && bctx.color = Sync then
      err ctx pos
        "'%s' can only be called in async contexts ('async function', 'execute async', or \
         'async { }')"
        name;
    let got = List.length args in
    (match List.find_opt (fun (ps, _) -> List.length ps = got) b.b_sigs with
    | None ->
      let arities =
        String.concat " or "
          (List.map (fun (ps, _) -> string_of_int (List.length ps)) b.b_sigs)
      in
      err ctx pos "'%s' expects %s argument(s), got %d" name arities got;
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
      TAny
    | Some (ps, ret) ->
      let arg_tys =
        List.map2
          (fun kind a ->
            let at = type_of ctx bctx env a in
            require_present ctx env a at ~use:(Printf.sprintf "an argument of '%s'" name);
            (match kind with
            | PNum ->
              if not (num_ok at) then
                err ctx a.epos "'%s' expects a number here, got %s" name (ty_to_string at)
            | PStr -> (
              match at with
              | TString | TAny -> ()
              | _ -> err ctx a.epos "'%s' expects a String here, got %s" name (ty_to_string at))
            | PStrOrList -> (
              match at with
              | TString | TList _ | TAny -> ()
              | _ ->
                err ctx a.epos "'%s' expects a String or list here, got %s" name
                  (ty_to_string at))
            | PPlayer -> (
              match at with
              | TPlayer | TAny -> ()
              | _ -> err ctx a.epos "'%s' expects a Player here, got %s" name (ty_to_string at))
            | PItem -> (
              match at with
              | TItem | TAny -> ()
              | _ -> err ctx a.epos "'%s' expects an Item here, got %s" name (ty_to_string at))
            | PLoc -> (
              match at with
              | TLocation | TAny -> ()
              | _ ->
                err ctx a.epos "'%s' expects a Location here, got %s" name (ty_to_string at))
            | PLoader -> (
              match at with
              | TWorldLoader | TAny -> ()
              | _ ->
                err ctx a.epos
                  "'%s' expects a world loader here (anvil_loader, polar_loader, or \
                   polar_storage_loader), got %s"
                  name (ty_to_string at))
            | PSchedOrName -> (
              match at with
              | TSchedule | TString | TAny -> ()
              | _ ->
                err ctx a.epos "'%s' expects a schedule handle or name (String) here, got %s" name
                  (ty_to_string at)));
            at)
          ps args
      in
      (match ret with
      | RTy t -> t
      | RNumJoin -> List.fold_left num_join TInteger arg_tys))
  | None ->
    (match looked with
    | Some t -> not_a_function ctx pos name t
    | None -> (
      match Hashtbl.find_opt ctx.import_privates name with
      | Some owner ->
        err ctx pos
          "function '%s' is private to %s; add 'export' to its declaration to call it from \
           here"
          name owner
      | None ->
        let candidates =
          Hashtbl.fold (fun k _ acc -> k :: acc) ctx.funcs []
          @ List.map (fun b -> b.b_name) builtins
        in
        err ctx pos "unknown function '%s'%s" name (suggestion name candidates)));
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
    TAny)

(* --- W-collections: method-call resolution (expression + statement) ---

   Resolve `<receiver>.<name>(<args>)` by the receiver's static type against the
   per-type method tables in registry.ml. Unknown method -> error + suggestion;
   wrong arity/args -> error; pure methods are expression-only and mutating
   methods statement-only (each rejected in the wrong context). Fn-argument
   methods take a lambda whose parameter is the element type and whose return
   role is validated (Boolean / comparable / free). *)
and method_owner_of ty =
  match unwrap ty with
  | TList elem -> Some (`List elem)
  | TMap (k, v) -> Some (`Map (k, v))
  | TString -> Some `Str
  | _ -> None

and method_kind_str = function `List _ -> "list" | `Map _ -> "map" | `Str -> "string"

and methods_of_owner = function
  | `List _ -> Registry.list_methods
  | `Map _ -> Registry.map_methods
  | `Str -> Registry.string_methods

and inst_mscheme owner (s : Registry.mscheme) : ty =
  match s with
  | SElem -> ( match owner with `List elem -> elem | _ -> TAny)
  | SKey -> ( match owner with `Map (k, _) -> k | _ -> TAny)
  | SVal -> ( match owner with `Map (_, v) -> v | _ -> TAny)
  | SSelf -> (
    match owner with `List elem -> TList elem | `Map (k, v) -> TMap (k, v) | `Str -> TString)
  | SInt -> TInteger
  | SStr -> TString
  | SBool -> TBoolean
  | SAny -> TAny
  | SList s -> TList (inst_mscheme owner s)
  | SOpt s -> TOptional (inst_mscheme owner s)
  | SFn (ps, role) ->
    TFunction
      {
        fn_async = false;
        fn_params = List.map (inst_mscheme owner) ps;
        fn_ret = (match role with FBool -> TBoolean | FComparable | FFree -> TAny);
      }

(* check a single method argument; returns its inferred type (for a lambda arg,
   the TFunction type — mapped's result element flows out of it) *)
and check_method_arg ctx bctx env owner name i (sch : Registry.mscheme) a : ty =
  match sch with
  | SFn (ps, role) -> check_method_lambda ctx bctx env owner name (i + 1) ps role a
  | _ ->
    let pty = inst_mscheme owner sch in
    let at = type_of ctx bctx env a in
    require_present ctx env a at ~use:(Printf.sprintf "argument %d of '%s'" (i + 1) name);
    if not (param_compat pty at) then
      err ctx a.epos "argument %d of '%s' expects %s, got %s" (i + 1) name (ty_to_string pty)
        (ty_to_string at);
    at

and check_method_lambda ctx bctx env owner name argno ps (role : Registry.fn_role) a : ty =
  let lt = type_of ctx bctx env a in
  (match lt with
  | TFunction f ->
    let want = List.length ps in
    ignore (List.map (inst_mscheme owner) ps);
    if List.length f.fn_params <> want then
      err ctx a.epos "the function argument of '%s' must take %d argument(s), got %d" name want
        (List.length f.fn_params);
    (match role with
    | FBool ->
      if not (boolish (unwrap f.fn_ret)) then
        err ctx a.epos "the function argument of '%s' must return a Boolean (got %s)" name
          (ty_to_string f.fn_ret)
    | FComparable -> (
      match unwrap f.fn_ret with
      | TInteger | TDouble | TString | TAny -> ()
      | other ->
        err ctx a.epos "the function argument of '%s' must return a Number or String (got %s)"
          name (ty_to_string other))
    | FFree -> ())
  | TAny -> ()
  | _ -> err ctx a.epos "argument %d of '%s' expects a function, got %s" argno name (ty_to_string lt));
  lt

(* W-blocks: methods on an immutable Block value. All are pure (return a value),
   so they are expression-only. `with` on a statically-known block id validates
   its property/value literals against the schema. *)
and check_block_method ctx bctx env pos recv name args ~as_stmt : ty =
  if as_stmt then
    err ctx pos
      "method '%s' returns a new Block and has no effect as a statement; use its result (e.g. \
       'set b to b.%s(...)')"
      name name;
  let block_methods = [ ("with", 2); ("property", 1); ("with_nbt", 1); ("get_tag", 1); ("with_tag", 2) ] in
  (match List.assoc_opt name block_methods with
  | None ->
    err ctx pos "unknown method '%s' on Block%s" name (suggestion name (List.map fst block_methods));
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
    TAny
  | Some arity ->
    let got = List.length args in
    if got <> arity then begin
      err ctx pos "method '%s' expects %d argument(s), got %d" name arity got;
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args
    end
    else
      List.iteri
        (fun i a ->
          let at = type_of ctx bctx env a in
          require_present ctx env a at ~use:(Printf.sprintf "argument %d of '%s'" (i + 1) name);
          (* every arg is a String (prop/value/tag name) except with_tag's value *)
          match (name, i) with
          | "with_tag", 1 -> ()
          | _ -> (
            match at with
            | TString | TAny -> ()
            | _ ->
              err ctx a.epos "argument %d of '%s' expects a String (got %s)" (i + 1) name
                (ty_to_string at)))
        args;
    (* static property/value validation for b.with("p", "v") when the receiver's
       block id is statically known *)
    (if name = "with" && got = 2 then
       match Tc_registry_checks.static_block_id recv with
       | Some bid -> (
         let p = List.nth args 0 in
         let v = List.nth args 1 in
         match Tc_registry_checks.literal_string p with
         | Some pname ->
           let value =
             match Tc_registry_checks.literal_string v with
             | Some s -> Some (s, v.epos)
             | None -> None
           in
           Tc_registry_checks.check_block_prop ctx ~id:bid ~name:pname ~name_pos:p.epos ~value
         | None -> ())
       | None -> ());
    (match name with
    | "with" | "with_nbt" | "with_tag" -> TBlock
    | "property" -> TOptional TString
    | "get_tag" -> TOptional TAny
    | _ -> TAny))

and check_method ctx bctx env pos recv name args ~as_stmt : ty =
  match recv.e with
  | EVar "super" ->
    (* super.<method>(args) invokes the base receiver method this custom-decl
       handler overrides; legal only inside an overriding method, and only for
       the overridden method name, with args matching the base signature *)
    (match bctx.override with
    | None ->
      err ctx pos
        "'super' is only valid inside a custom declaration method that overrides a base \
         receiver method";
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args
    | Some sg ->
      if name <> sg.h_event then
        err ctx pos
          "'super.%s' does not match the overridden method '%s'; a super call may only invoke \
           the base method being overridden"
          name sg.h_event;
      let want = List.length sg.h_params in
      let got = List.length args in
      if want <> got then
        err ctx pos "'super.%s' expects %d argument(s), got %d" sg.h_event want got;
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args);
    TAny
  | _ ->
  let rt = type_of ctx bctx env recv in
  require_present ctx env recv rt ~use:"the method receiver";
  if unwrap rt = TBlock then check_block_method ctx bctx env pos recv name args ~as_stmt
  else
  match method_owner_of rt with
  | None ->
    (match unwrap rt with
    | TAny -> ()
    | other ->
      err ctx pos "cannot call method '%s' on %s (only lists, maps, and Strings have methods)"
        name (ty_to_string other));
    List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
    TAny
  | Some owner -> (
    let methods = methods_of_owner owner in
    match Registry.find_method methods name with
    | None ->
      err ctx pos "unknown method '%s' on %s%s" name (ty_to_string (unwrap rt))
        (suggestion name (Registry.method_names methods));
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args;
      TAny
    | Some m ->
      if as_stmt && not m.me_mut then
        err ctx pos
          "method '%s' returns a value and has no effect as a statement; use its result in an \
           expression (e.g. 'set x to %s.%s(...)')"
          name (method_kind_str owner) name
      else if (not as_stmt) && m.me_mut then
        err ctx pos
          "method '%s' mutates the %s in place; call it as a statement, not inside an expression"
          name (method_kind_str owner);
      let expected = List.length m.me_params in
      let got = List.length args in
      let arg_tys =
        if got <> expected then begin
          err ctx pos "method '%s' expects %d argument(s), got %d" name expected got;
          List.map (fun a -> ignore (type_of ctx bctx env a); TAny) args
        end
        else List.mapi (fun i (sch, a) -> check_method_arg ctx bctx env owner name i sch a)
               (List.combine m.me_params args)
      in
      (* map sorted_by_value(_desc) needs comparable values, mirroring the
         sort_by_value builtin *)
      (match (owner, name) with
      | `Map (_, v), ("sorted_by_value" | "sorted_by_value_desc") -> (
        match v with
        | TInteger | TDouble | TString | TAny -> ()
        | _ ->
          err ctx pos "method '%s' needs a map with Number or String values (got map values of %s)"
            name (ty_to_string v))
      | _ -> ());
      match m.me_ret with
      | RScheme s -> inst_mscheme owner s
      | RMappedList ->
        let u = match arg_tys with [ TFunction f ] -> f.fn_ret | _ -> TAny in
        TList u)

and check_persist_subject ctx bctx env pos name pi subject =
  match (pi.pi_subject, subject) with
  | None, None -> ()
  | None, Some se ->
    (* the parser only parses 'for' after keyed names; defensive *)
    ignore (type_of ctx bctx env se);
    err ctx se.epos "persistent '%s' is not keyed; it cannot take 'for <subject>'" name
  | Some sty, None ->
    err ctx pos "'%s' is keyed by %s — use '%s for <%s>'" name (ty_to_string sty) name
      (String.lowercase_ascii (ty_to_string sty))
  | Some sty, Some se ->
    let st = type_of ctx bctx env se in
    require_present ctx env se st ~use:"the subject after 'for'";
    (* player-keyed persistents key by uuid string, so 'for Player' and
       'for OfflinePlayer' declarations both take either subject (phase 8) *)
    let player_keyed_interchange =
      match (sty, st) with
      | TPlayer, TOfflinePlayer | TOfflinePlayer, TPlayer -> true
      | _ -> false
    in
    if not (param_compat sty st || player_keyed_interchange) then
      err ctx se.epos "persistent '%s' is keyed by %s, but the subject after 'for' is %s" name
        (ty_to_string sty) (ty_to_string st)

and param_compat pty at =
  match (pty, at) with
  | TAny, _ | _, TAny -> true
  | (TInteger | TDouble), (TInteger | TDouble) -> true
  (* Player <: OfflinePlayer (phase 8): a live player flows anywhere an
     offline record is expected; the reverse needs '.player exists' narrowing *)
  | TOfflinePlayer, TPlayer -> true
  | TOptional pi, TOptional ai -> param_compat pi ai
  | TOptional pi, a -> param_compat pi a
  | TList pi, TList ai -> param_compat pi ai
  | TMap (pk, pv), TMap (ak, av) -> param_compat pk ak && param_compat pv av
  | TEither ps, a -> List.exists (fun p -> param_compat p a) ps
  | p, TEither ts -> List.exists (fun a -> param_compat p a) ts
  | p, a -> p = a

and check_interpolation ctx bctx env pos s =
  List.iter
    (fun frag ->
      if is_simple_path frag then begin
        let parts = String.split_on_char '.' frag in
        let synth =
          List.fold_left
            (fun acc part ->
              match acc with
              | None -> Some { e = EVar part; epos = pos }
              | Some t -> Some { e = EProp (t, part); epos = pos })
            None parts
        in
        match synth with
        | Some e ->
          ignore (type_of ctx bctx env e);
          (match parts with
          | [ root ] -> (
            match SM.find_opt root env.vars with
            | Some v when v.v_maybe && not (SM.mem root env.facts) ->
              err ctx pos
                "variable '%s' may not be assigned on all paths; assign it in every branch or \
                 check it with 'if %s exists'"
                root root
            | _ -> ())
          | _ -> ())
        | None -> ()
      end)
    (interp_paths s)

and cond_facts ctx bctx env e : (string * ty) list * (string * ty) list =
  match e.e with
  | EUnary ("NOT", c) ->
    let t, f = cond_facts ctx bctx env c in
    (f, t)
  | EUnary ("EXISTS", op) -> (
    match path_of op with
    | Some p ->
      let t = with_quiet ctx (fun () -> type_of ctx bctx env op) in
      ([ (path_key p, unwrap t) ], [])
    | None -> ([], []))
  | EBinary ("AND", a, b) ->
    let ta, _ = cond_facts ctx bctx env a in
    let tb, _ = cond_facts ctx bctx env b in
    (ta @ tb, [])
  | EBinary ("OR", a, b) ->
    let _, fa = cond_facts ctx bctx env a in
    let _, fb = cond_facts ctx bctx env b in
    ([], fa @ fb)
  | EBinary ("IS_TYPE", l, { e = EType tn; _ }) -> is_type_facts ctx bctx env l tn false
  | EBinary ("IS_NOT_TYPE", l, { e = EType tn; _ }) -> is_type_facts ctx bctx env l tn true
  | _ -> ([], [])

and is_type_facts ctx bctx env l tn negated =
  match path_of l with
  | None -> ([], [])
  | Some p ->
    (* `Number` matches the numeric members (Integer|Double); `Entity`
       matches every entity member — mobs ARE entities (phase 7), and a
       mob member narrows to Mob, keeping its typed rows; other names
       match their single mapped type *)
    let matches =
      if tn = "Number" then fun t -> t = TInteger || t = TDouble
      else if tn = "Entity" then fun t -> t = TEntity || t = TMob
        (* players ARE offline players (phase 8): an OfflinePlayer member
           test is true for Player values too *)
      else if tn = "OfflinePlayer" then fun t -> t = TOfflinePlayer || t = TPlayer
      else
        match ty_of_type_name tn with
        | Some tt -> fun t -> t = tt
        | None -> fun _ -> false
    in
    let key = path_key p in
    let cur = with_quiet ctx (fun () -> type_of ctx bctx env l) in
    let split ts =
      let yes, no = List.partition matches ts in
      match yes with
      | [] -> None
      | _ ->
        let y =
          match yes with
          | [] -> assert false
          | [ one ] -> one
          | m :: rest -> List.fold_left (if tn = "Number" then num_join else join) m rest
        in
        let n = match no with [] -> y | [ one ] -> one | rest -> TEither rest in
        Some (y, n)
    in
    let narrowed =
      match cur with
      | TEither ts -> split ts
      | TOptional (TEither ts) -> (
        match split ts with
        | Some (y, n) -> Some (y, TOptional n)
        | None -> None)
      | TOptional inner when matches inner -> Some (inner, TOptional inner)
      (* downcast (phase 7): an Entity value narrows to the tested runtime
         subtype in the positive branch (all_entities() elements, spawn
         bindings); the negative branch keeps Entity *)
      | TEntity when tn = "Player" -> Some (TPlayer, TEntity)
      | TEntity when tn = "Mob" -> Some (TMob, TEntity)
      (* downcast (phase 8): 'is a Player' on an OfflinePlayer value is a
         runtime online-instance check — the positive branch narrows to the
         live Player, the negative branch keeps the offline record *)
      | TOfflinePlayer when tn = "Player" -> Some (TPlayer, TOfflinePlayer)
      | _ -> None
    in
    (match narrowed with
    | None -> ([], [])
    | Some (yes, no) ->
      if negated then ([ (key, no) ], [ (key, yes) ]) else ([ (key, yes) ], [ (key, no) ]))
