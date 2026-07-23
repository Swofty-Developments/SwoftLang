open Ast
open Parser_state

let mke pos node = { e = node; epos = pos }

(* The six DICTIONARY free builtins (map_get/set/has/delete/keys/size) were
   removed in favour of the natural-language and method dialects. A literal call
   to any of them is now a parse error that points at both surface forms. Note
   this only blocks user-written calls: the natural forms desugar to the same
   map_* / prop / method emit nodes by building the AST directly, never through
   the call-parsing path guarded here. map_canvas is unrelated and stays. *)
let removed_map_builtins =
  [
    ("map_get", "map_get is removed; read a map with 'm[k]' or 'm.get(k)'");
    ("map_set", "map_set is removed; write 'set m at k to v' or 'm.set(k, v)'");
    ("map_has", "map_has is removed; write 'm has k' or 'm.has(k)'");
    ("map_delete", "map_delete is removed; write 'delete m at k' or 'm.delete(k)'");
    ("map_keys", "map_keys is removed; write 'keys of m' or 'm.keys'");
    ("map_size", "map_size is removed; write 'size of m' or 'm.size'");
  ]

(* A token that can begin the operand of a prefix natural expression like
   'sorted <list>' / 'reversed <list>'. Restricted to a plain identifier that is
   not one of the soft continuation words, so 'sorted' / 'reversed' stay legal
   variable names anywhere they are not immediately followed by such an operand
   (e.g. 'sorted.size', 'sorted otherwise x', a bare 'sorted'). *)
let natural_operand_ident = function
  | Token.IDENT s ->
    not
      (List.mem s
         [ "of"; "by"; "otherwise"; "exists"; "as"; "for"; "at"; "from"; "in"; "has" ])
  | _ -> false

(* lambda bodies are ordinary statement bodies; Parse_stmt installs its body
   parser here at load time to close the expr/stmt module cycle *)
let lambda_body_ref : (Parser_state.state -> stmt list) ref =
  ref (fun _ -> failwith "lambda body parser not installed")

(* v1.8.0 futures §2: `async { <stmts> ; <trailing?> }` in expression position.
   Parse_stmt installs the body parser here (it returns the statement list plus
   an optional trailing value expression) to close the expr/stmt module cycle. *)
let async_expr_body_ref : (Parser_state.state -> stmt list * expr option) ref =
  ref (fun _ -> failwith "async-expr body parser not installed")

(* polar_storage_loader(...) takes the storage{} backend syntax; Parse_decl
   installs its backend parser here at load time to close the module cycle *)
let backend_parser_ref : (Parser_state.state -> backend) ref =
  ref (fun _ -> failwith "backend parser not installed")

(* fragment sub-parses restart at line 1; pin every node to the string literal *)
let rec reposition p e =
  let node =
    match e.e with
    | EBinary (op, l, r) -> EBinary (op, reposition p l, reposition p r)
    | EUnary (op, x) -> EUnary (op, reposition p x)
    | ECall (name, args) -> ECall (name, List.map (reposition p) args)
    | EMethod (recv, name, args) ->
      EMethod (reposition p recv, name, List.map (reposition p) args)
    | EList items -> EList (List.map (reposition p) items)
    | EProp (target, name) -> EProp (reposition p target, name)
    | EPersistGet (name, subject) -> EPersistGet (name, Option.map (reposition p) subject)
    | EMap entries -> EMap (List.map (fun (k, v) -> (k, reposition p v)) entries)
    | EMapLit entries -> EMapLit (List.map (fun (k, v) -> (k, reposition p v)) entries)
    | other -> other
  in
  { e = node; epos = p }

let simple_interp_frag frag =
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

let rec parse_expr st = parse_or st

and parse_or st =
  let left = ref (parse_otherwise st) in
  let continue = ref true in
  while !continue do
    match peek_tok st with
    | Token.OR | Token.OROR ->
      let p = (!left).epos in
      ignore (advance st);
      left := mke p (EBinary ("OR", !left, parse_otherwise st))
    | _ -> continue := false
  done;
  !left

and parse_otherwise st =
  let left = ref (parse_and st) in
  let continue = ref true in
  while !continue do
    if soft st "otherwise" then begin
      let p = (!left).epos in
      ignore (advance st);
      left := mke p (EBinary ("OR_ELSE", !left, parse_and st))
    end
    else continue := false
  done;
  !left

and parse_and st =
  let left = ref (parse_not st) in
  let continue = ref true in
  while !continue do
    match peek_tok st with
    | Token.AND | Token.ANDAND ->
      let p = (!left).epos in
      ignore (advance st);
      left := mke p (EBinary ("AND", !left, parse_not st))
    | _ -> continue := false
  done;
  !left

and parse_not st =
  match peek_tok st with
  | Token.NOT ->
    let p = pos_here st in
    ignore (advance st);
    mke p (EUnary ("NOT", parse_not st))
  | _ -> parse_comparison st

and parse_comparison st =
  let left = ref (parse_additive st) in
  let continue = ref true in
  while !continue do
    let p = (!left).epos in
    match peek_tok st with
    | Token.EQUALS | Token.EQEQ ->
      ignore (advance st);
      left := mke p (EBinary ("EQUALS", !left, parse_additive st))
    | Token.NEQ ->
      ignore (advance st);
      left := mke p (EBinary ("NOT_EQUALS", !left, parse_additive st))
    | Token.LT ->
      ignore (advance st);
      left := mke p (EBinary ("LESS_THAN", !left, parse_additive st))
    | Token.GT ->
      ignore (advance st);
      left := mke p (EBinary ("GREATER_THAN", !left, parse_additive st))
    | Token.LE ->
      ignore (advance st);
      left := mke p (EBinary ("LESS_EQUALS", !left, parse_additive st))
    | Token.GE ->
      ignore (advance st);
      left := mke p (EBinary ("GREATER_EQUALS", !left, parse_additive st))
    | Token.CONTAINS ->
      ignore (advance st);
      left := mke p (EBinary ("CONTAINS", !left, parse_additive st))
    (* natural map membership: 'm has k' -> map_has(m, k), a Boolean. Reuses the
       existing map_has emit node; 'has' is a soft keyword so it stays a legal
       variable name outside this infix position. *)
    | Token.IDENT "has" ->
      ignore (advance st);
      left := mke p (ECall ("map_has", [ !left; parse_additive st ]))
    | Token.IDENT "exists" ->
      ignore (advance st);
      left := mke p (EUnary ("EXISTS", !left))
    | Token.IS ->
      ignore (advance st);
      let negated = matches st Token.NOT in
      (match (peek_tok st, peek2_tok st) with
      | Token.IDENT "missing", _ ->
        ignore (advance st);
        let ex = mke p (EUnary ("EXISTS", !left)) in
        left := if negated then ex else mke p (EUnary ("NOT", ex))
      | Token.IDENT ("a" | "an"), Token.IDENT _ ->
        ignore (advance st);
        let tpos = pos_here st in
        let type_name = expect_ident st "type name" in
        let op = if negated then "IS_NOT_TYPE" else "IS_TYPE" in
        left := mke p (EBinary (op, !left, mke tpos (EType type_name)))
      | Token.IDENT "running", _ ->
        (* W-tasks: '<obj>.tasks.<id> is [not] running' -> Boolean. The left
           operand must be a '<owner>.tasks.<id>' task path. *)
        ignore (advance st);
        let running =
          match (!left).e with
          | EProp (inner, id) -> (
            match inner.e with
            | EProp (owner, "tasks") -> mke p (ETaskRunning { tr_owner = owner; tr_id = id })
            | _ ->
              error st "'is running' requires a '<obj>.tasks.<id>' task on the left")
          | _ -> error st "'is running' requires a '<obj>.tasks.<id>' task on the left"
        in
        left := if negated then mke p (EUnary ("NOT", running)) else running
      | _ ->
        let op = if negated then "NOT_EQUALS" else "EQUALS" in
        left := mke p (EBinary (op, !left, parse_additive st)))
    | _ -> continue := false
  done;
  !left

and parse_additive st =
  let left = ref (parse_multiplicative st) in
  let continue = ref true in
  while !continue do
    let p = (!left).epos in
    match peek_tok st with
    | Token.PLUS ->
      ignore (advance st);
      left := mke p (EBinary ("ADD", !left, parse_multiplicative st))
    | Token.MINUS ->
      ignore (advance st);
      left := mke p (EBinary ("SUBTRACT", !left, parse_multiplicative st))
    | _ -> continue := false
  done;
  !left

and parse_multiplicative st =
  let left = ref (parse_unary st) in
  let continue = ref true in
  while !continue do
    let p = (!left).epos in
    match peek_tok st with
    | Token.STAR ->
      ignore (advance st);
      left := mke p (EBinary ("MULTIPLY", !left, parse_unary st))
    | Token.SLASH ->
      ignore (advance st);
      left := mke p (EBinary ("DIVIDE", !left, parse_unary st))
    | Token.PERCENT ->
      ignore (advance st);
      left := mke p (EBinary ("MODULO", !left, parse_unary st))
    | _ -> continue := false
  done;
  !left

and parse_unary st =
  match peek_tok st with
  | Token.MINUS ->
    let p = pos_here st in
    ignore (advance st);
    mke p (EUnary ("NEGATE", parse_unary st))
  | _ -> parse_postfix st

and parse_postfix st =
  let e = ref (parse_primary st) in
  let continue = ref true in
  while !continue do
    match peek_tok st with
    | Token.DOT ->
      ignore (advance st);
      let hpos = pos_here st in
      let name = expect_member_word st "property or method name after '.'" in
      (* `.name(args)` is a method call; `.name` (no parens) stays a property
         access — the zero-arg accessors (.size/.keys/.first/...) keep prop
         form (W-collections) *)
      if peek_tok st = Token.LPAREN then begin
        ignore (advance st);
        e := mke hpos (EMethod (!e, name, parse_call_args st))
      end
      else e := mke hpos (EProp (!e, name))
    | Token.LBRACKET ->
      (* map index read m[k] (phase 10): sugar for map_get(m, k), so it yields
         optional<V> and integrates the exists/otherwise discipline *)
      let hpos = pos_here st in
      ignore (advance st);
      let key = parse_expr st in
      expect st Token.RBRACKET "']' to close map index";
      e := mke hpos (ECall ("map_get", [ !e; key ]))
    | _ -> continue := false
  done;
  !e

and parse_primary st =
  let p = pos_here st in
  match peek_tok st with
  | Token.STRING s ->
    ignore (advance st);
    interp_string st p s
  | Token.NUMBER n ->
    ignore (advance st);
    mke p (ENumber { value = n; integer = not (String.contains n '.') })
  | Token.TRUE ->
    ignore (advance st);
    mke p (EBool true)
  | Token.FALSE ->
    ignore (advance st);
    mke p (EBool false)
  | Token.LPAREN ->
    ignore (advance st);
    let e = parse_expr st in
    expect st Token.RPAREN "')'";
    e
  | Token.LBRACKET ->
    ignore (advance st);
    let items = ref [] in
    if peek_tok st <> Token.RBRACKET then begin
      items := [ parse_expr st ];
      while matches st Token.COMMA do
        items := parse_expr st :: !items
      done
    end;
    expect st Token.RBRACKET "']' to close list literal";
    mke p (EList (List.rev !items))
  | Token.LBRACE ->
    (* map<K, V> literal (phase 11): { "k": expr, ... } or { 1: expr, ... }. A
       value-position brace with key: colon pairs is a map (blocks only appear in
       statement position, which never reaches parse_expr). The empty '{}' is
       rejected as ambiguous — use new_map() for an empty map. Keys are String or
       Integer literals; the checker enforces one key type per literal. *)
    ignore (advance st);
    if peek_tok st = Token.RBRACE then
      error st
        "empty map literal '{}' is ambiguous with a block; use new_map() to build an empty map";
    let entries = ref [] in
    let read_entry () =
      let key =
        match peek_tok st with
        | Token.STRING s ->
          ignore (advance st);
          MKStr s
        | Token.NUMBER n when not (String.contains n '.') ->
          ignore (advance st);
          MKInt n
        | t ->
          error st
            (Printf.sprintf
               "map keys must be string or integer literals, found %s" (Token.describe t))
      in
      expect st Token.COLON "':' after map key";
      let value = parse_expr st in
      entries := (key, value) :: !entries
    in
    read_entry ();
    while matches st Token.COMMA do
      if peek_tok st <> Token.RBRACE then read_entry ()
    done;
    expect st Token.RBRACE "'}' to close map literal";
    mke p (EMapLit (List.rev !entries))
  (* v1.8.0 futures §4: `all of <List<Future<T>>>` -> Future<List<T>>. Must be
     checked before the plain 'all' below (which is 'all players' / the broadcast
     keyword). *)
  | Token.ALL when soft2 st "of" ->
    ignore (advance st);
    ignore (advance st);
    mke p (EAllOf (parse_postfix st))
  | Token.ALL ->
    if peek2_tok st = Token.PLAYERS then (
      ignore (advance st);
      ignore (advance st);
      mke p EAllPlayers)
    else (
      ignore (advance st);
      mke p (EVar "all"))
  (* v1.8.0 futures §4: `any of <List<Future<T>>>` -> Future<T>. 'any' is a soft
     keyword, so it stays a legal variable name outside the 'any of' position. *)
  | Token.IDENT "any" when soft2 st "of" ->
    ignore (advance st);
    ignore (advance st);
    mke p (EAnyOf (parse_postfix st))
  (* v1.8.0 futures §2: `spawn <name>(<args>)` as a value -> Future<T>. Only the
     call form is an expression; `spawn particle/mob/entity` are statements. *)
  | Token.IDENT "spawn"
    when (match peek2_tok st with Token.IDENT _ -> true | _ -> false)
         && peek3_tok st = Token.LPAREN ->
    ignore (advance st);
    let name = expect_ident st "function name after 'spawn'" in
    expect st Token.LPAREN "'(' after function name";
    mke p (EFutureSpawn (name, parse_call_args st))
  (* v1.8.0 futures §3.1: `await <Future<T>>` -> T. Guarded on an operand-starting
     token so `await` stays a legal variable name elsewhere. *)
  | Token.IDENT "await"
    when (match peek2_tok st with
          | Token.IDENT _ | Token.LPAREN | Token.LBRACKET | Token.ALL -> true
          | _ -> false) ->
    ignore (advance st);
    mke p (EAwait (parse_postfix st))
  (* v1.8.0 futures §2: `async { ... }` as a value -> Future<trailing>. The
     statement form (no value used) is handled in parse_statement. *)
  | Token.IDENT "async" when peek2_tok st = Token.LBRACE ->
    ignore (advance st);
    let ae_body, ae_trailing = !async_expr_body_ref st in
    mke p (EAsyncExpr { ae_body; ae_trailing })
  | Token.IDENT "none" ->
    ignore (advance st);
    mke p ENone
  | Token.FUNCTION when peek2_tok st = Token.LPAREN ->
    ignore (advance st);
    parse_lambda st p ~lam_async:false
  | Token.IDENT "async" when peek2_tok st = Token.FUNCTION ->
    ignore (advance st);
    ignore (advance st);
    parse_lambda st p ~lam_async:true
  | Token.IDENT "polar_storage_loader" when peek2_tok st = Token.LPAREN ->
    (* the argument is storage-backend config syntax, not an expression *)
    ignore (advance st);
    ignore (advance st);
    let backend = !backend_parser_ref st in
    expect st Token.RPAREN "')' to close polar_storage_loader";
    mke p (ELoaderStorage backend)
  | Token.IDENT "schedule"
    when peek2_tok st = Token.LBRACE || soft2 st "after" || soft2 st "every" ->
    ignore (advance st);
    let sc_after = if eat_soft st "after" then Some (parse_duration st) else None in
    let sc_every = if eat_soft st "every" then Some (parse_duration st) else None in
    let sc_name =
      if matches st Token.AS then Some (expect_string st "schedule name after 'as'") else None
    in
    let sc_body = !lambda_body_ref st in
    mke p (ESchedule { sc_after; sc_every; sc_name; sc_body })
  (* W-viewers: 'viewers of <entity>' reads the entity's current viewer set as
     list<Player> (Minestom Viewable#getViewers) *)
  | Token.IDENT "viewers" when soft2 st "of" ->
    ignore (advance st);
    ignore (advance st);
    (* W-viewers §2: 'viewers of npc "n"' -> list<Player>. Npcs are name-keyed
       declarations, so this reads the fake player's Viewable#getViewers by name
       (same mechanism as 'viewers of <entity>'), rather than an entity handle. *)
    (match peek_tok st with
    | Token.IDENT "npc" when (match peek2_tok st with Token.STRING _ -> true | _ -> false) ->
      ignore (advance st);
      let name = expect_string st "npc name" in
      mke p (ECall ("viewers_of_npc", [ mke p (EString name) ]))
    | _ -> mke p (ECall ("viewers_of", [ parse_postfix st ])))
  (* removed DICTIONARY free builtins: a literal map_get/map_set/... call points
     at the natural and method forms (map_canvas is unaffected). *)
  | Token.IDENT name
    when peek2_tok st = Token.LPAREN && List.mem_assoc name removed_map_builtins ->
    error st (List.assoc name removed_map_builtins)
  (* natural collection/string accessors: '<word> of <expr>'. size/keys/values/
     first/last reuse the zero-arg property accessors (m.size / l.first); length/
     uppercase/lowercase reuse the existing string builtins. Context-sensitive:
     the 'of' lookahead is required, so every one of these words stays a legal
     variable name in any other position. *)
  | Token.IDENT ("size" | "keys" | "values" | "first" | "last") when soft2 st "of" ->
    let word = expect_ident st "collection accessor" in
    expect_soft st "of";
    mke p (EProp (parse_postfix st, word))
  | Token.IDENT "length" when soft2 st "of" ->
    ignore (advance st);
    expect_soft st "of";
    mke p (ECall ("length", [ parse_postfix st ]))
  | Token.IDENT ("uppercase" | "lowercase") when soft2 st "of" ->
    let word = expect_ident st "string accessor" in
    expect_soft st "of";
    mke p (ECall (word, [ parse_postfix st ]))
  (* natural list sorting/reversal, reusing the sort/sort_by/reverse builtins.
     'sorted l by <lambda>' takes an optional key function. *)
  | Token.IDENT "sorted" when natural_operand_ident (peek2_tok st) ->
    ignore (advance st);
    let lst = parse_postfix st in
    if eat_soft st "by" then mke p (ECall ("sort_by", [ lst; parse_expr st ]))
    else mke p (ECall ("sort", [ lst ]))
  | Token.IDENT "reversed" when natural_operand_ident (peek2_tok st) ->
    ignore (advance st);
    mke p (ECall ("reverse", [ parse_postfix st ]))
  (* W-blocks: block("id") / block("id", { facing: "north", ... }) — the second
     argument is an ident-keyed property brace (an EMap), not a general
     expression, so it is parsed here rather than through parse_call_args. *)
  | Token.IDENT "block" when peek2_tok st = Token.LPAREN ->
    ignore (advance st);
    ignore (advance st);
    let id = parse_expr st in
    let args =
      if matches st Token.COMMA then [ id; parse_block_prop_map st ] else [ id ]
    in
    expect st Token.RPAREN "')' to close block(...)";
    mke p (ECall ("block", args))
  (* §1 struct construction: `Struct { field: expr, ... }`. Recognised only for
     a prescanned struct type name, so a Capitalized variable followed by a
     block (rare, but legal) is never misparsed as a construction. *)
  | Token.IDENT name when peek2_tok st = Token.LBRACE && is_struct_name st name ->
    ignore (advance st);
    expect st Token.LBRACE "'{' after struct type name";
    let fields = ref [] in
    while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
      let fname = expect_ident st "struct field name" in
      expect st Token.COLON "':' after struct field name";
      let value = parse_expr st in
      fields := (fname, value) :: !fields;
      ignore (matches st Token.COMMA)
    done;
    expect st Token.RBRACE "'}' to close struct construction";
    mke p (EStructNew (name, List.rev !fields))
  | Token.IDENT name when peek2_tok st = Token.LPAREN ->
    ignore (advance st);
    ignore (advance st);
    mke p (ECall (name, parse_call_args st))
  | tok when persist_lookup st tok <> None ->
    let name, keyed =
      match persist_lookup st tok with Some x -> x | None -> assert false
    in
    ignore (advance st);
    if keyed && soft st "for" then begin
      ignore (advance st);
      mke p (EPersistGet (name, Some (parse_postfix st)))
    end
    else mke p (EPersistGet (name, None))
  | tok when ident_like tok <> None ->
    let name = expect_ident_like st "identifier" in
    mke p (EVar name)
  | tok ->
    error st (Printf.sprintf "Expected expression, found %s" (Token.describe tok))

and parse_lambda st p ~lam_async =
  expect st Token.LPAREN "'(' after 'function'";
  let params = ref [] in
  if peek_tok st <> Token.RPAREN then begin
    let param () =
      let p_pos = pos_here st in
      let p_name = expect_ident st "parameter name" in
      let p_type = if matches st Token.COLON then Some (Parse_type.parse_type st) else None in
      { p_name; p_type; p_pos }
    in
    params := [ param () ];
    while matches st Token.COMMA do
      params := param () :: !params
    done
  end;
  expect st Token.RPAREN "')' to close parameter list";
  let lam_body = !lambda_body_ref st in
  mke p (ELambda { lam_async; lam_params = List.rev !params; lam_body })

(* '{ prop: value, ... }' block-property brace: ident keys, expression values.
   Emitted as an EMap so the checker can validate each property against the
   block-state schema. *)
and parse_block_prop_map st =
  let bp = pos_here st in
  expect st Token.LBRACE "'{' to open the block property map";
  let entries = ref [] in
  if peek_tok st <> Token.RBRACE then begin
    let one () =
      let k = expect_ident st "block property name" in
      expect st Token.COLON "':' after block property name";
      (k, parse_expr st)
    in
    entries := [ one () ];
    while matches st Token.COMMA do
      if peek_tok st <> Token.RBRACE then entries := one () :: !entries
    done
  end;
  expect st Token.RBRACE "'}' to close the block property map";
  mke bp (EMap (List.rev !entries))

and parse_call_args st =
  if matches st Token.RPAREN then []
  else begin
    let args = ref [ parse_expr st ] in
    while matches st Token.COMMA do
      args := parse_expr st :: !args
    done;
    expect st Token.RPAREN "')' to close argument list";
    List.rev !args
  end

(* `${...}` fragments that are more than dotted paths desugar into real
   parsed expressions joined with CONCATENATE; strings whose fragments are
   all simple paths keep their runtime interpolation unchanged *)
and interp_string st p s =
  let frag_expr frag =
    match Lexer.tokenize frag with
    | exception Lexer.Error _ -> None
    | tokens -> (
      let sub =
        { file = st.file; tokens = Array.of_list tokens; pos = 0; persists = st.persists;
          structs = st.structs }
      in
      match parse_expr sub with
      | exception Diagnostics.Error _ -> None
      | e -> if peek_tok sub = Token.EOF then Some (reposition p e) else None)
  in
  (* find the '}' that closes a '${' opened at [open_i], honouring nested
     braces and string literals so a '}' inside a nested string (or map
     literal) does not close the interpolation prematurely *)
  let find_close open_i =
    let n = String.length s in
    let depth = ref 1 in
    let k = ref (open_i + 2) in
    let result = ref None in
    let in_str = ref false in
    while !result = None && !k < n do
      let c = s.[!k] in
      if !in_str then begin
        if c = '\\' && !k + 1 < n then k := !k + 2
        else begin
          if c = '"' then in_str := false;
          incr k
        end
      end
      else begin
        (match c with
         | '"' -> in_str := true
         | '{' -> incr depth
         | '}' -> decr depth; if !depth = 0 then result := Some !k
         | _ -> ());
        incr k
      end
    done;
    !result
  in
  let n = String.length s in
  let parts = ref [] in
  let buf = Buffer.create n in
  let complex = ref false in
  let flush_lit () =
    if Buffer.length buf > 0 then begin
      parts := `Lit (Buffer.contents buf) :: !parts;
      Buffer.clear buf
    end
  in
  let i = ref 0 in
  while !i < n do
    let consumed =
      if !i + 1 < n && s.[!i] = '$' && s.[!i + 1] = '{' then
        match find_close !i with
        | Some j ->
          let frag = String.sub s (!i + 2) (j - !i - 2) in
          let raw = String.sub s !i (j - !i + 1) in
          (* simple paths rooted at a persistent name must desugar too: the
             runtime path interpolator only knows variables, not persistents *)
          let persist_root =
            match String.split_on_char '.' frag with
            | root :: _ -> Hashtbl.mem st.persists root
            | [] -> false
          in
          (if simple_interp_frag frag && not persist_root then Buffer.add_string buf raw
           else
             match frag_expr frag with
             | Some e ->
               complex := true;
               flush_lit ();
               parts := `Expr e :: !parts
             | None -> Buffer.add_string buf raw);
          i := j + 1;
          true
        | None -> false
      else false
    in
    if not consumed then begin
      Buffer.add_char buf s.[!i];
      incr i
    end
  done;
  if not !complex then mke p (EString s)
  else begin
    flush_lit ();
    let to_expr = function
      | `Lit text -> mke p (EString text)
      | `Expr e -> e
    in
    match List.rev !parts with
    | [ `Expr e ] -> mke p (EBinary ("CONCATENATE", mke p (EString ""), e))
    | first :: rest ->
      List.fold_left
        (fun acc part -> mke p (EBinary ("CONCATENATE", acc, to_expr part)))
        (to_expr first) rest
    | [] -> mke p (EString "")
  end

let starts_expression = function
  | Token.STRING _ | Token.NUMBER _ | Token.TRUE | Token.FALSE | Token.LPAREN
  | Token.LBRACKET | Token.LBRACE | Token.MINUS | Token.NOT | Token.ALL | Token.IDENT _
  | Token.EVENT | Token.FUNCTION ->
    true
  | _ -> false

(* Target expression: bare `all` means broadcast, shipped as a string literal. *)
let parse_target st =
  let e = parse_expr st in
  match e.e with
  | EVar "all" -> { e with e = EString "all" }
  | _ -> e

let parse_lvalue st =
  let p = pos_here st in
  let root = expect_ident_like st "variable name" in
  let e = ref (mke p (EVar root)) in
  while peek_tok st = Token.DOT do
    ignore (advance st);
    let hpos = pos_here st in
    let name = expect_member_word st "property name after '.'" in
    e := mke hpos (EProp (!e, name))
  done;
  !e
