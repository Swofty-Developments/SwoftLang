open Ast
open Parser_state
open Parse_expr
open Parse_stmt

let parse_update_spec st =
  if eat_soft st "manual" then UManual
  else begin
    expect_soft st "every";
    UTicks (parse_duration st)
  end

let parse_scoreboard st =
  let sb_pos = pos_here st in
  ignore (advance st);
  let sb_name = expect_string st "scoreboard name" in
  expect st Token.LBRACE "'{' after scoreboard name";
  let title = ref None in
  let update = ref UManual in
  let numbers = ref "hidden" in
  let lines = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "title" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'title'";
      title := Some (parse_expr st)
    | Token.IDENT "update" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'update'";
      update := parse_update_spec st
    | Token.IDENT "numbers" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'numbers'";
      let v = expect_ident st "'hidden' or 'shown'" in
      if v <> "hidden" && v <> "shown" then
        error st (Printf.sprintf "Expected 'hidden' or 'shown', found '%s'" v);
      numbers := v
    | Token.IDENT "lines" ->
      ignore (advance st);
      let block = parse_dsl_block st DslLines in
      (match block.s with
      | SBlock ss -> lines := Some ss
      | _ -> ())
    | t -> error st (Printf.sprintf "Unknown scoreboard property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close scoreboard body";
  let sb_title =
    match !title with Some t -> t | None -> error st "scoreboard declaration requires 'title:'"
  in
  let sb_lines =
    match !lines with Some l -> l | None -> error st "scoreboard declaration requires 'lines { }'"
  in
  { sb_name; sb_exported = false; sb_title; sb_update = !update; sb_numbers = !numbers;
    sb_lines; sb_pos }

let parse_tablist st =
  let tl_pos = pos_here st in
  ignore (advance st);
  let tl_name = expect_string st "tablist name" in
  expect st Token.LBRACE "'{' after tablist name";
  let update = ref UManual in
  let header = ref None in
  let footer = ref None in
  let columns = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "update" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'update'";
      update := parse_update_spec st
    | Token.IDENT "header" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'header'";
      header := Some (parse_expr st)
    | Token.IDENT "footer" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'footer'";
      footer := Some (parse_expr st)
    | Token.IDENT "column" ->
      let col_pos = pos_here st in
      ignore (advance st);
      let block = parse_dsl_block st DslColumn in
      (match block.s with
      | SBlock ss -> columns := { col_body = ss; col_pos } :: !columns
      | _ -> ())
    | t -> error st (Printf.sprintf "Unknown tablist property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close tablist body";
  {
    tl_name;
    tl_exported = false;
    tl_update = !update;
    tl_header = !header;
    tl_footer = !footer;
    tl_columns = List.rev !columns;
    tl_pos;
  }

let parse_bossbar st =
  let bb_pos = pos_here st in
  ignore (advance st);
  let bb_name = expect_string st "bossbar name" in
  expect st Token.LBRACE "'{' after bossbar name";
  let text = ref None in
  let progress = ref None in
  let color = ref "white" in
  let style = ref "progress" in
  let update = ref UManual in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "text" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'text'";
      text := Some (parse_expr st)
    | Token.IDENT "progress" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'progress'";
      progress := Some (parse_expr st)
    | Token.IDENT "color" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'color'";
      color := expect_ident st "bossbar color"
    | Token.IDENT "style" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'style'";
      style := expect_ident st "bossbar style"
    | Token.IDENT "update" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'update'";
      update := parse_update_spec st
    | t -> error st (Printf.sprintf "Unknown bossbar property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close bossbar body";
  let bb_text =
    match !text with Some t -> t | None -> error st "bossbar declaration requires 'text:'"
  in
  let bb_progress =
    match !progress with Some p -> p | None -> error st "bossbar declaration requires 'progress:'"
  in
  { bb_name; bb_exported = false; bb_text; bb_progress; bb_color = !color; bb_style = !style;
    bb_update = !update; bb_pos }

(* --- first-class hologram declaration (GROUP D) --- *)
let parse_hologram st =
  let h_pos = pos_here st in
  ignore (advance st);
  let h_name = expect_string st "hologram name" in
  expect st Token.LBRACE "'{' after hologram name";
  let location = ref None in
  let billboard = ref "center" in
  let billboard_pos = ref h_pos in
  let scale = ref None in
  let viewable = ref None in
  let update = ref UManual in
  let lines = ref None in
  let handlers = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "viewable" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'viewable'";
      (match peek_tok st with
      | Token.TRUE ->
        ignore (advance st);
        viewable := Some true
      | Token.FALSE ->
        ignore (advance st);
        viewable := Some false
      | t ->
        error st
          (Printf.sprintf "Expected 'true' or 'false' after 'viewable:', found %s"
             (Token.describe t)))
    | Token.IDENT "location" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'location'";
      location := Some (parse_expr st)
    | Token.IDENT "billboard" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'billboard'";
      billboard_pos := pos_here st;
      billboard := expect_ident st "billboard mode (center, vertical, horizontal, or fixed)"
    | Token.IDENT "scale" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'scale'";
      scale := Some (parse_expr st)
    | Token.IDENT "update" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'update'";
      update := parse_update_spec st
    | Token.IDENT "lines" ->
      ignore (advance st);
      let block = parse_dsl_block st DslLines in
      (match block.s with
      | SBlock ss -> lines := Some ss
      | _ -> ())
    | Token.IDENT name when starts_with_on name ->
      let h = parse_inline_handler st in
      if List.exists (fun (x : inline_handler) -> x.ih_event = h.ih_event) !handlers then
        error st (Printf.sprintf "Duplicate handler '%s'" h.ih_event);
      handlers := h :: !handlers
    | t -> error st (Printf.sprintf "Unknown hologram property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close hologram body";
  let h_location =
    match !location with Some l -> l | None -> error st "hologram declaration requires 'location:'"
  in
  let h_lines =
    match !lines with Some l -> l | None -> error st "hologram declaration requires 'lines { }'"
  in
  {
    h_name;
    h_exported = false;
    h_location;
    h_billboard = !billboard;
    h_billboard_pos = !billboard_pos;
    h_scale = !scale;
    h_viewable = !viewable;
    h_update = !update;
    h_lines;
    h_handlers = List.rev !handlers;
    h_pos;
  }

(* --- first-class npc declaration (GROUP C) --- *)

(* parse_npc_skin lives in Parse_stmt (shared with 'set npc ... skin'); it is
   in scope here through 'open Parse_stmt'. *)

(* on_click(player) { ... } / on_left_click(player) { ... }: a named player
   binder then a statement body *)
let parse_npc_handler st =
  expect st Token.LPAREN "'(' after npc click handler";
  let binder = expect_ident st "the player binder name" in
  expect st Token.RPAREN "')' after the click handler parameter";
  (binder, parse_body st)

let parse_npc st =
  let n_pos = pos_here st in
  ignore (advance st);
  let n_name = expect_string st "npc name" in
  expect st Token.LBRACE "'{' after npc name";
  let location = ref None in
  let display_name = ref None in
  let skin = ref None in
  let look = ref false in
  let viewable = ref None in
  let on_click = ref None in
  let on_left = ref None in
  let handlers = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "viewable" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'viewable'";
      (match peek_tok st with
      | Token.TRUE ->
        ignore (advance st);
        viewable := Some true
      | Token.FALSE ->
        ignore (advance st);
        viewable := Some false
      | t ->
        error st
          (Printf.sprintf "Expected 'true' or 'false' after 'viewable:', found %s"
             (Token.describe t)))
    | Token.IDENT "location" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'location'";
      location := Some (parse_expr st)
    | Token.IDENT "name" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'name'";
      display_name := Some (parse_expr st)
    | Token.IDENT "skin" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'skin'";
      skin := Some (parse_npc_skin st)
    | Token.IDENT "look_at_players" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'look_at_players'";
      (match peek_tok st with
      | Token.TRUE ->
        ignore (advance st);
        look := true
      | Token.FALSE ->
        ignore (advance st);
        look := false
      | t ->
        error st
          (Printf.sprintf "Expected 'true' or 'false' after 'look_at_players:', found %s"
             (Token.describe t)))
    | Token.IDENT "on_click" ->
      ignore (advance st);
      on_click := Some (parse_npc_handler st)
    | Token.IDENT "on_left_click" ->
      ignore (advance st);
      on_left := Some (parse_npc_handler st)
    (* on_click/on_left_click are matched above; any other on_<name> flows here
       and surfaces an unknown-handler error against the npc handler table *)
    | Token.IDENT name when starts_with_on name ->
      let h = parse_inline_handler st in
      if List.exists (fun (x : inline_handler) -> x.ih_event = h.ih_event) !handlers then
        error st (Printf.sprintf "Duplicate handler '%s'" h.ih_event);
      handlers := h :: !handlers
    | t -> error st (Printf.sprintf "Unknown npc property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close npc body";
  let n_location =
    match !location with Some l -> l | None -> error st "npc declaration requires 'location:'"
  in
  {
    n_name;
    n_exported = false;
    n_location;
    n_display_name = !display_name;
    n_skin = !skin;
    n_look_at_players = !look;
    n_viewable = !viewable;
    n_on_click = !on_click;
    n_on_left_click = !on_left;
    n_handlers = List.rev !handlers;
    n_pos;
  }
