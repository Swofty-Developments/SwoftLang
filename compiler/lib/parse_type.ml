open Ast
open Parser_state

let base_of_name = function
  | "String" -> Some "STRING"
  | "Integer" | "int" -> Some "INTEGER"
  | "Double" | "double" -> Some "DOUBLE"
  | "Boolean" | "bool" -> Some "BOOLEAN"
  | "Player" -> Some "PLAYER"
  | "Location" -> Some "LOCATION"
  | "World" -> Some "WORLD"
  | "Item" -> Some "ITEM"
  | "Mob" -> Some "MOB"
  | "Display" -> Some "DISPLAY"
  | "Song" -> Some "SONG"
  | "Skin" -> Some "SKIN"
  | "Canvas" -> Some "CANVAS"
  | "Schedule" -> Some "SCHEDULE"
  | "WorldLoader" -> Some "WORLD_LOADER"
  | "Entity" -> Some "ENTITY"
  | "Block" -> Some "BLOCK"
  | "Vec" -> Some "VEC"
  | "OfflinePlayer" -> Some "OFFLINE_PLAYER"
  | _ -> None

(* Closing '>' of a generic type: a '>=' here is the '>' close followed by '='
   (maximal munch split), e.g. either<Player|Location>=sender *)
let expect_type_close st =
  match peek st with
  | Token.GT, _, _ -> ignore (advance st)
  | Token.GE, line, col -> st.tokens.(st.pos) <- (Token.EQUALS, line, col + 1)
  | t, _, _ ->
    error st (Printf.sprintf "Expected '>' to close generic type, found %s" (Token.describe t))

let rec parse_type st =
  match peek st with
  | Token.EITHER, _, _ ->
    ignore (advance st);
    expect st Token.LT "'<' after 'either'";
    let subs = ref [ parse_type st ] in
    while matches st Token.PIPE do
      subs := parse_type st :: !subs
    done;
    expect_type_close st;
    DEither (List.rev !subs)
  | Token.IDENT "Optional", _, _ when peek2_tok st = Token.LT ->
    ignore (advance st);
    ignore (advance st);
    let sub = parse_type st in
    expect_type_close st;
    DOptional sub
  | Token.IDENT "List", _, _ when peek2_tok st = Token.LT ->
    ignore (advance st);
    ignore (advance st);
    let sub = parse_type st in
    expect_type_close st;
    DList sub
  | Token.IDENT "Map", _, _ when peek2_tok st = Token.LT ->
    (* Map<K, V>: K in {String, Integer} (phase 11). Map<V> is sugar for
       Map<String, V> — the back-compat form with only a value type written. *)
    ignore (advance st);
    ignore (advance st);
    let first = parse_type st in
    if matches st Token.COMMA then begin
      (* two-arg form: first is the key type, which must be String, Integer, or
         Player (Player keys serialize by uuid on the Java side) *)
      (match first with
      | DSimple "STRING" | DSimple "INTEGER" | DSimple "PLAYER" -> ()
      | _ ->
        error st
          "map keys must be String, Integer, or Player (Map<String, V>, Map<Integer, V>, or \
           Map<Player, V>)");
      let value = parse_type st in
      expect_type_close st;
      DMap (first, value)
    end
    else begin
      expect_type_close st;
      DMap (DSimple "STRING", first)
    end
  | Token.IDENT (("map" | "list" | "optional" | "either") as low), _, _
    when peek2_tok st = Token.LT ->
    (* v1.6.0: the generic type constructors are now PascalCase. Point the old
       lowercase spelling at its capitalized replacement. *)
    error st
      (Printf.sprintf "the %s type is now written `%s<...>` (all types are PascalCase)" low
         (String.capitalize_ascii low))
  | Token.IDENT name, line, col ->
    ignore (advance st);
    (match base_of_name name with
    | Some base -> DSimple base
    | None ->
      (* §2 nominal custom types: a Capitalized unknown name is a candidate
         custom type (mob/item); preserve it verbatim so the typechecker can
         resolve it against the declared types. A lowercase unknown name is a
         genuine typo — keep the legacy warning + UNKNOWN degradation. *)
      if String.length name > 0 && name.[0] >= 'A' && name.[0] <= 'Z' then DSimple name
      else begin
        Printf.eprintf "%s:%d:%d: warning: unknown type '%s', treating as UNKNOWN\n" st.file line
          col name;
        DSimple "UNKNOWN"
      end)
  | t, _, _ ->
    error st (Printf.sprintf "Expected type name, found %s" (Token.describe t))

let parse_default st =
  match peek st with
  | Token.IDENT v, _, _ | Token.STRING v, _, _ | Token.NUMBER v, _, _ ->
    ignore (advance st);
    v
  | Token.TRUE, _, _ ->
    ignore (advance st);
    "true"
  | Token.FALSE, _, _ ->
    ignore (advance st);
    "false"
  | t, _, _ ->
    error st (Printf.sprintf "Expected default value, found %s" (Token.describe t))
