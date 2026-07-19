{
open Token

exception Error of string * int * int

let keyword_table =
  let tbl = Hashtbl.create 32 in
  List.iter
    (fun (k, v) -> Hashtbl.add tbl k v)
    [ ("command", COMMAND); ("event", EVENT); ("if", IF); ("else", ELSE);
      ("halt", HALT); ("send", SEND); ("teleport", TELEPORT); ("to", TO);
      ("is", IS); ("not", NOT); ("either", EITHER); ("cancel", CANCEL);
      ("set", SET); ("contains", CONTAINS); ("and", AND); ("or", OR);
      ("function", FUNCTION); ("return", RETURN); ("loop", LOOP);
      ("while", WHILE); ("times", TIMES); ("as", AS);
      ("broadcast", BROADCAST); ("call", CALL); ("all", ALL);
      ("players", PLAYERS); ("true", TRUE); ("false", FALSE) ];
  tbl

let start_pos lexbuf =
  let p = Lexing.lexeme_start_p lexbuf in
  (p.Lexing.pos_lnum, p.Lexing.pos_cnum - p.Lexing.pos_bol + 1)

let ret lexbuf tok =
  let line, col = start_pos lexbuf in
  (tok, line, col)
}

let digit = ['0'-'9']
let ident_start = ['A'-'Z' 'a'-'z' '_']
let ident_char = ['A'-'Z' 'a'-'z' '0'-'9' '_']

rule token = parse
  | [' ' '\t' '\r']+ { token lexbuf }
  | '\n' { Lexing.new_line lexbuf; token lexbuf }
  | "//" [^ '\n']* { token lexbuf }
  | "/*"
      { let line, col = start_pos lexbuf in
        block_comment line col lexbuf;
        token lexbuf }
  | digit+ ('.' digit+)? as n { ret lexbuf (NUMBER n) }
  | ident_start ident_char* as id
      { let tok =
          match Hashtbl.find_opt keyword_table id with
          | Some kw -> kw
          | None -> IDENT id
        in
        ret lexbuf tok }
  | '"'
      { let line, col = start_pos lexbuf in
        let value = string_body line col (Buffer.create 16) lexbuf in
        (STRING value, line, col) }
  | "==" { ret lexbuf EQEQ }
  | "!=" { ret lexbuf NEQ }
  | "<=" { ret lexbuf LE }
  | ">=" { ret lexbuf GE }
  | "&&" { ret lexbuf ANDAND }
  | "||" { ret lexbuf OROR }
  | "->" { ret lexbuf ARROW }
  | ':' { ret lexbuf COLON }
  | '=' { ret lexbuf EQUALS }
  | '<' { ret lexbuf LT }
  | '>' { ret lexbuf GT }
  | '+' { ret lexbuf PLUS }
  | '-' { ret lexbuf MINUS }
  | '*' { ret lexbuf STAR }
  | '/' { ret lexbuf SLASH }
  | '%' { ret lexbuf PERCENT }
  | '(' { ret lexbuf LPAREN }
  | ')' { ret lexbuf RPAREN }
  | '{' { ret lexbuf LBRACE }
  | '}' { ret lexbuf RBRACE }
  | '|' { ret lexbuf PIPE }
  | ',' { ret lexbuf COMMA }
  | ".." { ret lexbuf DOTDOT }
  | '.' { ret lexbuf DOT }
  | '[' { ret lexbuf LBRACKET }
  | ']' { ret lexbuf RBRACKET }
  | eof { ret lexbuf EOF }
  | _ as c
      { let line, col = start_pos lexbuf in
        raise (Error (Printf.sprintf "Unexpected character '%c'" c, line, col)) }

and string_body sline scol buf = parse
  | '"' { Buffer.contents buf }
  | "\\n" { Buffer.add_char buf '\n'; string_body sline scol buf lexbuf }
  | "\\t" { Buffer.add_char buf '\t'; string_body sline scol buf lexbuf }
  | "\\r" { Buffer.add_char buf '\r'; string_body sline scol buf lexbuf }
  | "\\\"" { Buffer.add_char buf '"'; string_body sline scol buf lexbuf }
  | "\\\\" { Buffer.add_char buf '\\'; string_body sline scol buf lexbuf }
  | '\\' (_ as c)
      { if c = '\n' then Lexing.new_line lexbuf;
        Buffer.add_char buf c;
        string_body sline scol buf lexbuf }
  | '\n'
      { Lexing.new_line lexbuf;
        Buffer.add_char buf '\n';
        string_body sline scol buf lexbuf }
  | eof { raise (Error ("Unterminated string literal", sline, scol)) }
  | _ as c { Buffer.add_char buf c; string_body sline scol buf lexbuf }

and block_comment sline scol = parse
  | "*/" { () }
  | '\n' { Lexing.new_line lexbuf; block_comment sline scol lexbuf }
  | eof { raise (Error ("Unterminated block comment", sline, scol)) }
  | _ { block_comment sline scol lexbuf }

{
let tokenize source =
  let lexbuf = Lexing.from_string source in
  let rec loop acc =
    let ((tok, _, _) as t) = token lexbuf in
    let acc = t :: acc in
    match tok with
    | EOF -> List.rev acc
    | _ -> loop acc
  in
  loop []
}
