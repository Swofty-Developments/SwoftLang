open Ast
open Parser_state
open Parse_expr
open Parse_stmt
open Parse_type

let parse_arguments st =
  expect st Token.LBRACE "'{' after 'arguments'";
  let args = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    let arg_pos = pos_here st in
    let arg_name = expect_ident st "argument name" in
    expect st Token.COLON "':' after argument name";
    let arg_type = parse_type st in
    let arg_default = if matches st Token.EQUALS then Some (parse_default st) else None in
    args := { arg_name; arg_type; arg_default; arg_pos } :: !args
  done;
  expect st Token.RBRACE "'}' to close arguments block";
  List.rev !args

let parse_execute st =
  let ex_async = eat_soft st "async" in
  { ex_async; ex_stmts = parse_body st }

let parse_command_group st =
  let cmd_pos = pos_here st in
  expect st Token.COMMAND "'command'";
  let first = expect_string st "command name" in
  let rec collect_names names =
    if matches st Token.COMMA then
      match peek_tok st with
      | Token.COMMAND ->
        ignore (advance st);
        collect_names (expect_string st "command name after 'command'" :: names)
      | Token.STRING s ->
        ignore (advance st);
        collect_names (s :: names)
      | Token.LBRACE -> names
      | t ->
        error st (Printf.sprintf "Expected command name after ',', found %s" (Token.describe t))
    else names
  in
  let names = List.rev (collect_names [ first ]) in
  expect st Token.LBRACE "'{' after command name(s)";
  let permission = ref None in
  let description = ref None in
  let arguments = ref [] in
  let execute = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek st with
    | Token.IDENT "permission", _, _ ->
      ignore (advance st);
      expect st Token.COLON "':' after 'permission'";
      permission := Some (expect_string st "permission string")
    | Token.IDENT "description", _, _ ->
      ignore (advance st);
      expect st Token.COLON "':' after 'description'";
      description := Some (expect_string st "description string")
    | Token.IDENT "arguments", _, _ ->
      ignore (advance st);
      arguments := !arguments @ parse_arguments st
    | Token.IDENT "execute", _, _ ->
      ignore (advance st);
      execute := Some (parse_execute st)
    | Token.IDENT name, _, _ ->
      error st (Printf.sprintf "Unknown command property: %s" name)
    | t, _, _ ->
      error st (Printf.sprintf "Expected command property, found %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close command body";
  {
    names;
    permission = !permission;
    description = !description;
    arguments = !arguments;
    execute = !execute;
    cmd_pos;
  }

let parse_event st =
  let ev_pos = pos_here st in
  expect st Token.EVENT "'event'";
  let ev_name = expect_ident st "event name" in
  expect st Token.LBRACE "'{' after event name";
  let priority = ref 0 in
  let execute = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek st with
    | Token.IDENT "priority", _, _ ->
      ignore (advance st);
      expect st Token.COLON "':' after 'priority'";
      priority := parse_int_number st "priority value"
    | Token.IDENT "execute", _, _ ->
      ignore (advance st);
      execute := Some (parse_execute st)
    | Token.IDENT name, _, _ ->
      error st (Printf.sprintf "Unknown event property: %s" name)
    | t, _, _ ->
      error st (Printf.sprintf "Expected event property, found %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close event body";
  { ev_name; priority = !priority; ev_execute = !execute; ev_pos }

let parse_function st ~fn_async =
  let fn_pos = pos_here st in
  expect st Token.FUNCTION "'function'";
  let fn_name = expect_ident st "function name" in
  expect st Token.LPAREN "'(' after function name";
  let params = ref [] in
  if peek_tok st <> Token.RPAREN then begin
    let param () =
      let p_pos = pos_here st in
      let p_name = expect_ident st "parameter name" in
      let p_type = if matches st Token.COLON then Some (parse_type st) else None in
      { p_name; p_type; p_pos }
    in
    params := [ param () ];
    while matches st Token.COMMA do
      params := param () :: !params
    done
  end;
  expect st Token.RPAREN "')' to close parameter list";
  let body = parse_body st in
  { fn_name; fn_async; fn_exported = false; params = List.rev !params; body; fn_pos }

(* http { port: 8080, bind: "127.0.0.1" } — both fields optional *)
let parse_http_conf st =
  expect st Token.LBRACE "'{' after 'http'";
  let port = ref 8080 in
  let bind = ref "0.0.0.0" in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "port" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'port'";
      port := parse_int_number st "port number"
    | Token.IDENT "bind" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'bind'";
      bind := expect_string st "bind address"
    | t -> error st (Printf.sprintf "Unknown http property: %s" (Token.describe t)));
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close http block";
  { hc_port = !port; hc_bind = !bind }

(* fishing { min_bite: 5 seconds, max_bite: 30 seconds } — the randomized
   bite window of the native fishing engine (phase 8); both fields optional *)
let parse_fishing_conf st =
  expect st Token.LBRACE "'{' after 'fishing'";
  let min_bite = ref 100 in
  let max_bite = ref 600 in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "min_bite" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'min_bite'";
      min_bite := parse_duration st
    | Token.IDENT "max_bite" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'max_bite'";
      max_bite := parse_duration st
    | t -> error st (Printf.sprintf "Unknown fishing property: %s" (Token.describe t)));
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close fishing block";
  { fi_min_bite = !min_bite; fi_max_bite = !max_bite }

(* permissions { "user": ["perm", ...] ... } — the default PermissionProvider's
   config list (design 6D) *)
let parse_permissions st =
  expect st Token.LBRACE "'{' after 'permissions'";
  let entries = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    let user = expect_string st "user name" in
    expect st Token.COLON "':' after user name";
    expect st Token.LBRACKET "'[' to open the permission list";
    let perms = ref [] in
    if peek_tok st <> Token.RBRACKET then begin
      perms := [ expect_string st "permission string" ];
      while matches st Token.COMMA do
        perms := expect_string st "permission string" :: !perms
      done
    end;
    expect st Token.RBRACKET "']' to close the permission list";
    entries := (user, List.rev !perms) :: !entries;
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close permissions block";
  List.rev !entries

let parse_server st =
  let sv_pos = pos_here st in
  ignore (advance st);
  expect st Token.LBRACE "'{' after 'server'";
  let auth = ref AuthOffline in
  let host = ref None in
  let port = ref None in
  let brand = ref None in
  let motd = ref None in
  let http = ref None in
  let fishing = ref None in
  let favicon = ref None in
  let permissions = ref [] in
  let open_to_lan = ref false in
  let lighting = ref true in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "auth" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'auth'";
      (match peek_tok st with
      | Token.IDENT "mojang" ->
        ignore (advance st);
        auth := AuthMojang
      | Token.IDENT "velocity" ->
        ignore (advance st);
        auth := AuthVelocity (expect_string st "velocity secret")
      | Token.IDENT "bungeecord" ->
        ignore (advance st);
        auth := AuthBungeecord
      | Token.IDENT "offline" ->
        ignore (advance st);
        auth := AuthOffline
      | t ->
        error st
          (Printf.sprintf
             "Expected auth mode ('mojang', 'velocity \"secret\"', 'bungeecord', or 'offline'), \
              found %s"
             (Token.describe t)))
    | Token.IDENT "host" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'host'";
      host := Some (expect_string st "host string")
    | Token.IDENT "port" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'port'";
      port := Some (parse_int_number st "port number")
    | Token.IDENT "brand" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'brand'";
      brand := Some (expect_string st "brand string")
    | Token.IDENT "motd" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'motd'";
      motd := Some (expect_string st "motd string")
    | Token.IDENT "http" ->
      ignore (advance st);
      http := Some (parse_http_conf st)
    | Token.IDENT "fishing" ->
      ignore (advance st);
      fishing := Some (parse_fishing_conf st)
    | Token.IDENT "favicon" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'favicon'";
      favicon := Some (expect_string st "favicon png path")
    | Token.IDENT "permissions" ->
      ignore (advance st);
      permissions := parse_permissions st
    | Token.IDENT "open_to_lan" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'open_to_lan'";
      (match peek_tok st with
      | Token.TRUE ->
        ignore (advance st);
        open_to_lan := true
      | Token.FALSE ->
        ignore (advance st);
        open_to_lan := false
      | t ->
        error st
          (Printf.sprintf "Expected 'true' or 'false' after 'open_to_lan:', found %s"
             (Token.describe t)))
    | Token.IDENT "lighting" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'lighting'";
      (match peek_tok st with
      | Token.TRUE ->
        ignore (advance st);
        lighting := true
      | Token.FALSE ->
        ignore (advance st);
        lighting := false
      | t ->
        error st
          (Printf.sprintf "Expected 'true' or 'false' after 'lighting:', found %s"
             (Token.describe t)))
    | t -> error st (Printf.sprintf "Unknown server property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close server body";
  {
    sv_auth = !auth;
    sv_host = !host;
    sv_port = !port;
    sv_brand = !brand;
    sv_motd = !motd;
    sv_http = !http;
    sv_fishing = !fishing;
    sv_favicon = !favicon;
    sv_permissions = !permissions;
    sv_open_to_lan = !open_to_lan;
    sv_lighting = !lighting;
    sv_pos;
  }

(* --- storage / persistent declarations --- *)

let parse_backend st =
  match peek_tok st with
  | Token.IDENT "files" ->
    ignore (advance st);
    BFiles (expect_string st "storage directory path")
  | Token.IDENT "sqlite" ->
    ignore (advance st);
    BSqlite (expect_string st "sqlite database path")
  | Token.IDENT "mongodb" ->
    ignore (advance st);
    BMongodb (expect_string st "mongodb connection uri")
  | Token.IDENT "mysql" ->
    ignore (advance st);
    expect st Token.LBRACE "'{' after 'mysql'";
    let host = ref "localhost" in
    let port = ref 3306 in
    let database = ref "swoftlang" in
    let user = ref "root" in
    let password = ref "" in
    while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
      (match peek_tok st with
      | Token.IDENT "host" ->
        ignore (advance st);
        expect st Token.COLON "':' after 'host'";
        host := expect_string st "host string"
      | Token.IDENT "port" ->
        ignore (advance st);
        expect st Token.COLON "':' after 'port'";
        port := parse_int_number st "port number"
      | Token.IDENT "database" ->
        ignore (advance st);
        expect st Token.COLON "':' after 'database'";
        database := expect_string st "database name"
      | Token.IDENT "user" ->
        ignore (advance st);
        expect st Token.COLON "':' after 'user'";
        user := expect_string st "user string"
      | Token.IDENT "password" ->
        ignore (advance st);
        expect st Token.COLON "':' after 'password'";
        password := expect_string st "password string"
      | t -> error st (Printf.sprintf "Unknown mysql property: %s" (Token.describe t)));
      ignore (matches st Token.COMMA)
    done;
    expect st Token.RBRACE "'}' to close mysql block";
    BMysql
      { host = !host; port = !port; database = !database; user = !user; password = !password }
  | t ->
    error st
      (Printf.sprintf
         "Expected storage backend ('files', 'sqlite', 'mysql', or 'mongodb'), found %s"
         (Token.describe t))

let parse_storage st =
  let st_pos = pos_here st in
  ignore (advance st);
  expect st Token.LBRACE "'{' after 'storage'";
  let backend = ref (BFiles "swoftlang-data") in
  let flush = ref 600 in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "backend" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'backend'";
      backend := parse_backend st
    | Token.IDENT "flush" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'flush'";
      expect_soft st "every";
      flush := parse_duration st
    | t -> error st (Printf.sprintf "Unknown storage property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close storage body";
  { st_backend = !backend; st_flush_ticks = !flush; st_pos }

let parse_persistent st =
  let pd_pos = pos_here st in
  ignore (advance st);
  let pd_name = expect_ident st "persistent variable name" in
  let pd_subject = if eat_soft st "for" then Some (parse_type st) else None in
  expect st Token.COLON "':' before the persistent type";
  let pd_type = parse_type st in
  if peek_tok st <> Token.EQUALS then
    error st
      "persistent declarations require a default value ('= <value>') so reads are always \
       defined";
  ignore (advance st);
  let pd_default = parse_expr st in
  { pd_name; pd_subject; pd_type; pd_default; pd_pos }

(* close the expr/decl module cycle: polar_storage_loader(...) parses its
   argument with the storage backend grammar above *)
let () = Parse_expr.backend_parser_ref := parse_backend
