open Ast
open Parser_state
open Parse_decl
open Parse_expr
open Parse_gui
open Parse_ui
open Parse_content

(* Declarations that may carry the 'export' prefix (design 6A). Commands and
   events always register — they are effects, not symbols — so 'export' on
   them is rejected with an explanatory error. *)
let parse_exported st ~functions ~guis ~scoreboards ~tablists ~bossbars ~holograms ~npcs ~items
    ~mobs =
  ignore (advance st);
  (* 'export' *)
  match peek_tok st with
  | Token.FUNCTION ->
    functions := { (parse_function st ~fn_async:false) with fn_exported = true } :: !functions
  | Token.IDENT "async" when peek2_tok st = Token.FUNCTION ->
    ignore (advance st);
    functions := { (parse_function st ~fn_async:true) with fn_exported = true } :: !functions
  | Token.IDENT "gui" -> guis := { (parse_gui st) with g_exported = true } :: !guis
  | Token.IDENT "scoreboard" ->
    scoreboards := { (parse_scoreboard st) with sb_exported = true } :: !scoreboards
  | Token.IDENT "tablist" ->
    tablists := { (parse_tablist st) with tl_exported = true } :: !tablists
  | Token.IDENT "bossbar" ->
    bossbars := { (parse_bossbar st) with bb_exported = true } :: !bossbars
  | Token.IDENT "hologram" ->
    holograms := { (parse_hologram st) with h_exported = true } :: !holograms
  | Token.IDENT "npc" -> npcs := { (parse_npc st) with n_exported = true } :: !npcs
  | Token.IDENT "item" -> items := { (parse_item_decl st) with it_exported = true } :: !items
  | Token.IDENT "mob" -> mobs := { (parse_mob_decl st) with mb_exported = true } :: !mobs
  | Token.COMMAND | Token.EVENT ->
    error st
      "commands and events always register when their module is imported (they are effects, \
       not symbols); remove 'export'"
  | t ->
    error st
      (Printf.sprintf
         "'export' can only prefix 'function', 'item', 'mob', 'gui', 'scoreboard', 'tablist', \
          'bossbar', 'hologram', or 'npc' declarations, found %s"
         (Token.describe t))

let parse ~file source =
  let tokens =
    try Lexer.tokenize source
    with Lexer.Error (msg, line, col) -> Diagnostics.raise_error ~file ~line ~col msg
  in
  let tokens = Array.of_list tokens in
  let st = { file; tokens; pos = 0; persists = prescan_persistents tokens } in
  let imports = ref [] in
  let module_vars = ref [] in
  let commands = ref [] in
  let events = ref [] in
  let functions = ref [] in
  let guis = ref [] in
  let scoreboards = ref [] in
  let tablists = ref [] in
  let bossbars = ref [] in
  let holograms = ref [] in
  let npcs = ref [] in
  let servers = ref [] in
  let storages = ref [] in
  let persistents = ref [] in
  let items = ref [] in
  let mobs = ref [] in
  let packet_listeners = ref [] in
  let apis = ref [] in
  let schedulers = ref [] in
  let fishing_loots = ref [] in
  while peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.COMMAND -> commands := parse_command_group st :: !commands
    | Token.EVENT -> events := parse_event st :: !events
    | Token.FUNCTION -> functions := parse_function st ~fn_async:false :: !functions
    | Token.IDENT "async" when peek2_tok st = Token.FUNCTION ->
      ignore (advance st);
      functions := parse_function st ~fn_async:true :: !functions
    | Token.IDENT "import" ->
      let im_pos = pos_here st in
      ignore (advance st);
      let im_spec = expect_string st "module name or relative path after 'import'" in
      imports := { im_spec; im_pos } :: !imports
    | Token.IDENT "export" ->
      parse_exported st ~functions ~guis ~scoreboards ~tablists ~bossbars ~holograms ~npcs ~items
        ~mobs
    | Token.IDENT "var" ->
      let mv_pos = pos_here st in
      ignore (advance st);
      let mv_name = expect_ident st "module variable name" in
      if peek_tok st <> Token.EQUALS then
        error st "module variable declarations require an initial value ('= <value>')";
      ignore (advance st);
      let mv_value = parse_expr st in
      module_vars := { mv_name; mv_value; mv_pos } :: !module_vars
    | Token.IDENT "gui" -> guis := parse_gui st :: !guis
    | Token.IDENT "scoreboard" -> scoreboards := parse_scoreboard st :: !scoreboards
    | Token.IDENT "tablist" -> tablists := parse_tablist st :: !tablists
    | Token.IDENT "bossbar" -> bossbars := parse_bossbar st :: !bossbars
    | Token.IDENT "hologram" -> holograms := parse_hologram st :: !holograms
    | Token.IDENT "npc" -> npcs := parse_npc st :: !npcs
    | Token.IDENT "server" -> servers := parse_server st :: !servers
    | Token.IDENT "storage" -> storages := parse_storage st :: !storages
    | Token.IDENT "persistent" -> persistents := parse_persistent st :: !persistents
    | Token.IDENT "item" -> items := parse_item_decl st :: !items
    | Token.IDENT "mob" -> mobs := parse_mob_decl st :: !mobs
    | Token.IDENT "on" when soft2 st "packet" ->
      packet_listeners := parse_packet_listener st :: !packet_listeners
    (* 'on <EventName> { body }' — event-handler shorthand (must come after the
       'on packet' branch above) *)
    | Token.IDENT "on" -> events := parse_event_shorthand st :: !events
    | Token.IDENT "api" -> apis := parse_api_decl st :: !apis
    | Token.IDENT "every" -> schedulers := parse_sched_decl st :: !schedulers
    | Token.IDENT "fishing_loot" -> fishing_loots := parse_fishing_loot st :: !fishing_loots
    | t ->
      error st
        (Printf.sprintf
           "Expected 'import', 'export', 'var', 'command', 'event', 'function', 'gui', \
            'scoreboard', 'tablist', 'bossbar', 'hologram', 'npc', 'server', 'storage', \
            'persistent', 'item', 'mob', 'api', 'every', 'fishing_loot', or 'on packet', found %s"
           (Token.describe t))
  done;
  {
    imports = List.rev !imports;
    module_vars = List.rev !module_vars;
    commands = List.rev !commands;
    events = List.rev !events;
    functions = List.rev !functions;
    guis = List.rev !guis;
    scoreboards = List.rev !scoreboards;
    tablists = List.rev !tablists;
    bossbars = List.rev !bossbars;
    holograms = List.rev !holograms;
    npcs = List.rev !npcs;
    servers = List.rev !servers;
    storages = List.rev !storages;
    persistents = List.rev !persistents;
    items = List.rev !items;
    mobs = List.rev !mobs;
    packet_listeners = List.rev !packet_listeners;
    apis = List.rev !apis;
    schedulers = List.rev !schedulers;
    fishing_loots = List.rev !fishing_loots;
  }
