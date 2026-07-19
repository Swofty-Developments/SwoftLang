open Ast

type state = {
  file : string;
  tokens : (Token.t * int * int) array;
  mutable pos : int;
  (* persistent declaration table (name -> keyed?), collected in a prescan so
     keyed persistent names are known before any body parses *)
  persists : (string, bool) Hashtbl.t;
}

(* Two-pass support: scan the raw token stream for top-level (brace depth 0)
   `persistent <name> [for <Type>] : ...` declarations before real parsing, so
   `kills for <expr>` parses as a keyed persistent access anywhere in the file
   regardless of declaration order. *)
let prescan_persistents tokens =
  let tbl = Hashtbl.create 8 in
  let n = Array.length tokens in
  let depth = ref 0 in
  for i = 0 to n - 1 do
    let t, _, _ = tokens.(i) in
    match t with
    | Token.LBRACE -> incr depth
    | Token.RBRACE -> decr depth
    | Token.IDENT "persistent" when !depth = 0 && i + 2 < n -> (
      match (tokens.(i + 1), tokens.(i + 2)) with
      | (Token.IDENT name, _, _), (Token.COLON, _, _) -> Hashtbl.replace tbl name false
      | (Token.IDENT name, _, _), (Token.IDENT "for", _, _) -> Hashtbl.replace tbl name true
      | _ -> ())
    | _ -> ()
  done;
  tbl

let persist_lookup st tok =
  match tok with
  | Token.IDENT name -> (
    match Hashtbl.find_opt st.persists name with
    | Some keyed -> Some (name, keyed)
    | None -> None)
  | _ -> None

let peek st = st.tokens.(st.pos)

let peek_tok st =
  let t, _, _ = peek st in
  t

let peek2_tok st =
  if st.pos + 1 < Array.length st.tokens then
    let t, _, _ = st.tokens.(st.pos + 1) in
    t
  else Token.EOF

let peek3_tok st =
  if st.pos + 2 < Array.length st.tokens then
    let t, _, _ = st.tokens.(st.pos + 2) in
    t
  else Token.EOF

let pos_here st =
  let _, line, col = peek st in
  { line; col }

let advance st =
  let t = peek st in
  if st.pos < Array.length st.tokens - 1 then st.pos <- st.pos + 1;
  t

let error st msg =
  let _, line, col = peek st in
  Diagnostics.raise_error ~file:st.file ~line ~col msg

let expect st tok what =
  let t, _, _ = peek st in
  if t = tok then ignore (advance st)
  else error st (Printf.sprintf "Expected %s, found %s" what (Token.describe t))

let matches st tok =
  if peek_tok st = tok then (
    ignore (advance st);
    true)
  else false

let expect_ident st what =
  match peek st with
  | Token.IDENT s, _, _ ->
    ignore (advance st);
    s
  | t, _, _ ->
    error st (Printf.sprintf "Expected %s, found %s" what (Token.describe t))

let expect_string st what =
  match peek st with
  | Token.STRING s, _, _ ->
    ignore (advance st);
    s
  | t, _, _ ->
    error st (Printf.sprintf "Expected %s, found %s" what (Token.describe t))

let soft st kw =
  match peek_tok st with
  | Token.IDENT s -> s = kw
  | _ -> false

let soft2 st kw =
  match peek2_tok st with
  | Token.IDENT s -> s = kw
  | _ -> false

let eat_soft st kw =
  if soft st kw then (
    ignore (advance st);
    true)
  else false

let expect_soft st kw =
  if not (eat_soft st kw) then
    error st (Printf.sprintf "Expected '%s', found %s" kw (Token.describe (peek_tok st)))

let ident_like = function
  | Token.IDENT s -> Some s
  | Token.EVENT -> Some "event"
  | Token.COMMAND -> Some "command"
  | Token.SEND -> Some "send"
  | Token.TELEPORT -> Some "teleport"
  | Token.IF -> Some "if"
  | Token.ELSE -> Some "else"
  | Token.HALT -> Some "halt"
  | Token.TO -> Some "to"
  | Token.SET -> Some "set"
  | Token.CANCEL -> Some "cancel"
  | _ -> None

let expect_ident_like st what =
  match ident_like (peek_tok st) with
  | Some s ->
    ignore (advance st);
    s
  | None ->
    error st (Printf.sprintf "Expected %s, found %s" what (Token.describe (peek_tok st)))

(* a member name after '.' (property or method) may be any keyword-shaped word:
   a collection method or accessor (contains/set/values/is_empty/...) can
   collide with a reserved word, and in member position there is no ambiguity
   with the keyword's grammar role. Includes every English-word token. *)
let member_word = function
  | Token.IDENT s -> Some s
  | Token.COMMAND -> Some "command"
  | Token.EVENT -> Some "event"
  | Token.IF -> Some "if"
  | Token.ELSE -> Some "else"
  | Token.HALT -> Some "halt"
  | Token.SEND -> Some "send"
  | Token.TELEPORT -> Some "teleport"
  | Token.TO -> Some "to"
  | Token.IS -> Some "is"
  | Token.NOT -> Some "not"
  | Token.EITHER -> Some "either"
  | Token.CANCEL -> Some "cancel"
  | Token.SET -> Some "set"
  | Token.CONTAINS -> Some "contains"
  | Token.AND -> Some "and"
  | Token.OR -> Some "or"
  | Token.FUNCTION -> Some "function"
  | Token.RETURN -> Some "return"
  | Token.LOOP -> Some "loop"
  | Token.WHILE -> Some "while"
  | Token.TIMES -> Some "times"
  | Token.AS -> Some "as"
  | Token.BROADCAST -> Some "broadcast"
  | Token.CALL -> Some "call"
  | Token.ALL -> Some "all"
  | Token.PLAYERS -> Some "players"
  | _ -> None

let expect_member_word st what =
  match member_word (peek_tok st) with
  | Some s ->
    ignore (advance st);
    s
  | None ->
    error st (Printf.sprintf "Expected %s, found %s" what (Token.describe (peek_tok st)))

let parse_int_number st what =
  match peek st with
  | Token.NUMBER raw, _, _ ->
    ignore (advance st);
    (match int_of_string_opt raw with
    | Some i -> i
    | None -> int_of_float (float_of_string raw))
  | t, _, _ ->
    error st (Printf.sprintf "Expected %s, found %s" what (Token.describe t))

(* Duration literal: <int> ticks|seconds|millis -> tick count *)
let parse_duration st =
  match peek st with
  | Token.NUMBER raw, _, _ ->
    ignore (advance st);
    let n =
      match int_of_string_opt raw with
      | Some i -> i
      | None -> error st "Duration must be an integer literal"
    in
    (match peek st with
    | Token.IDENT ("ticks" | "tick"), _, _ ->
      ignore (advance st);
      n
    | Token.IDENT ("seconds" | "second"), _, _ ->
      ignore (advance st);
      n * 20
    | Token.IDENT "millis", _, _ ->
      ignore (advance st);
      let t = n / 50 in
      if t < 1 then 1 else t
    | t, _, _ ->
      error st
        (Printf.sprintf "Expected duration unit ('ticks', 'seconds', or 'millis'), found %s"
           (Token.describe t)))
  | t, _, _ ->
    error st (Printf.sprintf "Expected duration, found %s" (Token.describe t))
