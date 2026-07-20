open Ast
open Parser_state

let mke pos node = { e = node; epos = pos }

(* lambda bodies are ordinary statement bodies; Parse_stmt installs its body
   parser here at load time to close the expr/stmt module cycle *)
let lambda_body_ref : (Parser_state.state -> stmt list) ref =
  ref (fun _ -> failwith "lambda body parser not installed")

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
  | Token.ALL ->
    if peek2_tok st = Token.PLAYERS then (
      ignore (advance st);
      ignore (advance st);
      mke p EAllPlayers)
    else (
      ignore (advance st);
      mke p (EVar "all"))
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
        { file = st.file; tokens = Array.of_list tokens; pos = 0; persists = st.persists }
      in
      match parse_expr sub with
      | exception Diagnostics.Error _ -> None
      | e -> if peek_tok sub = Token.EOF then Some (reposition p e) else None)
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
        match String.index_from_opt s (!i + 2) '}' with
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
