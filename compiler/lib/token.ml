type t =
  | IDENT of string
  | STRING of string
  | NUMBER of string
  | COMMAND
  | EVENT
  | IF
  | ELSE
  | HALT
  | SEND
  | TELEPORT
  | TO
  | IS
  | NOT
  | EITHER
  | CANCEL
  | SET
  | CONTAINS
  | AND
  | OR
  | FUNCTION
  | RETURN
  | LOOP
  | WHILE
  | TIMES
  | AS
  | BROADCAST
  | CALL
  | ALL
  | PLAYERS
  | TRUE
  | FALSE
  | COLON
  | EQUALS
  | EQEQ
  | NEQ
  | LT
  | GT
  | LE
  | GE
  | ANDAND
  | OROR
  | PLUS
  | MINUS
  | STAR
  | SLASH
  | PERCENT
  | LPAREN
  | RPAREN
  | LBRACE
  | RBRACE
  | PIPE
  | COMMA
  | DOT
  | DOTDOT
  | LBRACKET
  | RBRACKET
  | ARROW
  | AT
  | EOF

let describe = function
  | IDENT s -> Printf.sprintf "identifier '%s'" s
  | STRING _ -> "string literal"
  | NUMBER n -> Printf.sprintf "number '%s'" n
  | COMMAND -> "'command'"
  | EVENT -> "'event'"
  | IF -> "'if'"
  | ELSE -> "'else'"
  | HALT -> "'halt'"
  | SEND -> "'send'"
  | TELEPORT -> "'teleport'"
  | TO -> "'to'"
  | IS -> "'is'"
  | NOT -> "'not'"
  | EITHER -> "'either'"
  | CANCEL -> "'cancel'"
  | SET -> "'set'"
  | CONTAINS -> "'contains'"
  | AND -> "'and'"
  | OR -> "'or'"
  | FUNCTION -> "'function'"
  | RETURN -> "'return'"
  | LOOP -> "'loop'"
  | WHILE -> "'while'"
  | TIMES -> "'times'"
  | AS -> "'as'"
  | BROADCAST -> "'broadcast'"
  | CALL -> "'call'"
  | ALL -> "'all'"
  | PLAYERS -> "'players'"
  | TRUE -> "'true'"
  | FALSE -> "'false'"
  | COLON -> "':'"
  | EQUALS -> "'='"
  | EQEQ -> "'=='"
  | NEQ -> "'!='"
  | LT -> "'<'"
  | GT -> "'>'"
  | LE -> "'<='"
  | GE -> "'>='"
  | ANDAND -> "'&&'"
  | OROR -> "'||'"
  | PLUS -> "'+'"
  | MINUS -> "'-'"
  | STAR -> "'*'"
  | SLASH -> "'/'"
  | PERCENT -> "'%'"
  | LPAREN -> "'('"
  | RPAREN -> "')'"
  | LBRACE -> "'{'"
  | RBRACE -> "'}'"
  | PIPE -> "'|'"
  | COMMA -> "','"
  | DOT -> "'.'"
  | DOTDOT -> "'..'"
  | LBRACKET -> "'['"
  | RBRACKET -> "']'"
  | ARROW -> "'->'"
  | AT -> "'@'"
  | EOF -> "end of file"
