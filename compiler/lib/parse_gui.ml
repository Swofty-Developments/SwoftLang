open Ast
open Parser_state
open Parse_expr
open Parse_stmt

(* [10..16, 19..25] -> expanded int list *)
let parse_slot_list st =
  expect st Token.LBRACKET "'['";
  let ints = ref [] in
  let item () =
    let a = parse_int_number st "slot index" in
    if matches st Token.DOTDOT then begin
      let b = parse_int_number st "slot range end" in
      if b < a then error st "Slot range end must not be below its start";
      for i = a to b do
        ints := i :: !ints
      done
    end
    else ints := a :: !ints
  in
  item ();
  while matches st Token.COMMA do
    item ()
  done;
  expect st Token.RBRACKET "']' to close slot list";
  List.rev !ints

let click_filters = [ "left"; "right"; "shift_left"; "shift_right"; "middle"; "double"; "any" ]

let parse_click_filter st =
  if matches st Token.LPAREN then begin
    let f = expect_ident st "click filter" in
    if not (List.mem f click_filters) then
      error st
        (Printf.sprintf
           "Unknown click filter '%s'; valid filters: left, right, shift_left, shift_right, \
            middle, double, any"
           f);
    expect st Token.RPAREN "')' after click filter";
    f
  end
  else "any"

let parse_item_fields st ~is_pos =
  let material = ref None in
  let skull = ref None in
  let name = ref None in
  let lore = ref None in
  let amount = ref None in
  let glint = ref None in
  let set_field r field v =
    match !r with
    | Some _ -> error st (Printf.sprintf "Duplicate item field '%s'" field)
    | None -> r := Some v
  in
  let continue = ref true in
  while !continue do
    (match peek_tok st with
    | Token.IDENT ("material" | "skull" | "name" | "lore" | "amount" | "glint")
      when peek2_tok st = Token.COLON ->
      let field = expect_ident st "item field" in
      expect st Token.COLON "':'";
      (match field with
      | "material" -> set_field material field (parse_expr st)
      | "skull" -> set_field skull field (parse_expr st)
      | "name" -> set_field name field (parse_expr st)
      | "amount" -> set_field amount field (parse_expr st)
      | "glint" -> set_field glint field (parse_expr st)
      | _ ->
        let v = parse_expr st in
        let items = match v.e with EList items -> items | _ -> [ v ] in
        set_field lore field items);
      ignore (matches st Token.COMMA)
    | _ -> continue := false)
  done;
  {
    is_material = !material;
    is_skull = !skull;
    is_name = !name;
    is_lore = !lore;
    is_amount = !amount;
    is_glint = !glint;
    is_pos;
  }

let parse_item_spec_block st =
  let is_pos = pos_here st in
  expect st Token.LBRACE "'{' after 'item'";
  let spec = parse_item_fields st ~is_pos in
  expect st Token.RBRACE "'}' to close item block";
  spec

(* item(MATERIAL [, amount] [, name: e] [, lore: e] ...) in fill/border position *)
let parse_fill_value st =
  if soft st "item" && peek2_tok st = Token.LPAREN then begin
    let is_pos = pos_here st in
    ignore (advance st);
    ignore (advance st);
    let material = ref None in
    let skull = ref None in
    let name = ref None in
    let lore = ref None in
    let amount = ref None in
    let glint = ref None in
    let positional = ref 0 in
    let first = ref true in
    while peek_tok st <> Token.RPAREN && peek_tok st <> Token.EOF do
      if not !first then expect st Token.COMMA "','";
      first := false;
      match (peek_tok st, peek2_tok st) with
      | Token.IDENT field, Token.COLON ->
        ignore (advance st);
        ignore (advance st);
        let v = parse_expr st in
        (match field with
        | "material" -> material := Some v
        | "skull" -> skull := Some v
        | "name" -> name := Some v
        | "amount" -> amount := Some v
        | "glint" -> glint := Some v
        | "lore" ->
          let items = match v.e with EList items -> items | _ -> [ v ] in
          lore := Some items
        | f -> error st (Printf.sprintf "Unknown item field '%s'" f))
      | _ ->
        let v = parse_expr st in
        incr positional;
        (match !positional with
        | 1 -> material := Some v
        | 2 -> amount := Some v
        | _ -> error st "item(...) takes at most two positional arguments (material, amount)")
    done;
    expect st Token.RPAREN "')' to close item(...)";
    FSpec
      {
        is_material = !material;
        is_skull = !skull;
        is_name = !name;
        is_lore = !lore;
        is_amount = !amount;
        is_glint = !glint;
        is_pos;
      }
  end
  else FExpr (parse_expr st)

let parse_slot_body st ~gs_slots ~gs_pos =
  expect st Token.LBRACE "'{' to open slot body";
  let item = ref None in
  let clicks = ref [] in
  let refresh = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "item" ->
      ignore (advance st);
      (match !item with
      | Some _ -> error st "Duplicate 'item' block in slot"
      | None -> item := Some (parse_item_spec_block st))
    | Token.IDENT "on_click" ->
      ignore (advance st);
      let ch_filter = parse_click_filter st in
      clicks := { ch_filter; ch_body = parse_body st } :: !clicks
    | Token.IDENT "refresh" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'refresh'";
      refresh := Some (parse_duration st)
    | t ->
      error st
        (Printf.sprintf "Expected 'item', 'on_click', or 'refresh' in slot body, found %s"
           (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close slot body";
  match !item with
  | None -> error st "Slot body must contain an 'item { ... }' block"
  | Some gs_item -> { gs_slots; gs_item; gs_clicks = List.rev !clicks; gs_refresh = !refresh; gs_pos }

let parse_paginate st =
  let gp_pos = pos_here st in
  expect st Token.LBRACE "'{' after 'paginate'";
  let source = ref None in
  let slots = ref None in
  let render = ref None in
  let on_click = ref None in
  let prev_slot = ref None in
  let next_slot = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "source" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'source'";
      source := Some (parse_expr st)
    | Token.IDENT "slots" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'slots'";
      if soft st "grid" && peek2_tok st = Token.LPAREN then begin
        ignore (advance st);
        ignore (advance st);
        let a = parse_int_number st "grid start slot" in
        expect st Token.COMMA "',' between grid bounds";
        let b = parse_int_number st "grid end slot" in
        expect st Token.RPAREN "')' to close grid(...)";
        let acc = ref [] in
        for i = a to b do
          if i mod 9 <> 0 && i mod 9 <> 8 then acc := i :: !acc
        done;
        slots := Some (List.rev !acc)
      end
      else slots := Some (parse_slot_list st)
    | Token.IDENT "render" ->
      ignore (advance st);
      render := Some (parse_item_spec_block st)
    | Token.IDENT "on_click" ->
      ignore (advance st);
      on_click := Some (parse_body st)
    | Token.IDENT "prev_slot" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'prev_slot'";
      prev_slot := Some (parse_int_number st "slot index")
    | Token.IDENT "next_slot" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'next_slot'";
      next_slot := Some (parse_int_number st "slot index")
    | t -> error st (Printf.sprintf "Unknown paginate property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close paginate block";
  match (!source, !render) with
  | None, _ -> error st "paginate block requires a 'source:' expression"
  | _, None -> error st "paginate block requires a 'render { ... }' block"
  | Some gp_source, Some gp_render ->
    {
      gp_source;
      gp_slots = (match !slots with Some s -> s | None ->
        (* default 7x4 interior grid, slots 10..43 *)
        let acc = ref [] in
        for i = 10 to 43 do
          if i mod 9 <> 0 && i mod 9 <> 8 then acc := i :: !acc
        done;
        List.rev !acc);
      gp_render;
      gp_on_click = !on_click;
      gp_prev_slot = !prev_slot;
      gp_next_slot = !next_slot;
      gp_pos;
    }

let parse_gui st =
  let g_pos = pos_here st in
  ignore (advance st);
  let g_name = expect_string st "gui name" in
  expect st Token.LBRACE "'{' after gui name";
  let rows = ref None in
  let title = ref None in
  let state = ref [] in
  let fill = ref None in
  let border = ref None in
  let slots = ref [] in
  let editable = ref [] in
  let paginate = ref None in
  let refresh = ref None in
  let on_open = ref None in
  let on_close = ref None in
  let on_click = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "rows" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'rows'";
      rows := Some (parse_int_number st "row count")
    | Token.IDENT "title" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'title'";
      title := Some (parse_expr st)
    | Token.IDENT "state" ->
      ignore (advance st);
      expect st Token.LBRACE "'{' after 'state'";
      while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
        let key = expect_ident st "state key" in
        expect st Token.COLON "':' after state key";
        state := (key, parse_expr st) :: !state;
        ignore (matches st Token.COMMA)
      done;
      expect st Token.RBRACE "'}' to close state block"
    | Token.IDENT "fill" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'fill'";
      fill := Some (parse_fill_value st)
    | Token.IDENT "border" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'border'";
      border := Some (parse_fill_value st)
    | Token.IDENT "slot" ->
      let gs_pos = pos_here st in
      ignore (advance st);
      let n = parse_int_number st "slot index" in
      slots := parse_slot_body st ~gs_slots:[ n ] ~gs_pos :: !slots
    | Token.IDENT "slots" ->
      let gs_pos = pos_here st in
      ignore (advance st);
      let ns = parse_slot_list st in
      slots := parse_slot_body st ~gs_slots:ns ~gs_pos :: !slots
    | Token.IDENT "editable" ->
      let ge_pos = pos_here st in
      ignore (advance st);
      let ge_slots = parse_slot_list st in
      expect st Token.LBRACE "'{' to open editable body";
      let on_change = ref None in
      while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
        match peek_tok st with
        | Token.IDENT "on_change" ->
          ignore (advance st);
          on_change := Some (parse_body st)
        | t ->
          error st (Printf.sprintf "Expected 'on_change' in editable body, found %s" (Token.describe t))
      done;
      expect st Token.RBRACE "'}' to close editable body";
      editable := { ge_slots; ge_on_change = !on_change; ge_pos } :: !editable
    | Token.IDENT "paginate" ->
      ignore (advance st);
      (match !paginate with
      | Some _ -> error st "Duplicate 'paginate' block"
      | None -> paginate := Some (parse_paginate st))
    | Token.IDENT "refresh" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'refresh'";
      refresh := Some (parse_duration st)
    | Token.IDENT "on_open" ->
      ignore (advance st);
      on_open := Some (parse_body st)
    | Token.IDENT "on_close" ->
      ignore (advance st);
      on_close := Some (parse_body st)
    | Token.IDENT "on_click" ->
      ignore (advance st);
      on_click := Some (parse_body st)
    | t -> error st (Printf.sprintf "Unknown gui property: %s" (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close gui body";
  let g_rows =
    match !rows with Some r -> r | None -> error st "gui declaration requires 'rows:'"
  in
  let g_title =
    match !title with Some t -> t | None -> error st "gui declaration requires 'title:'"
  in
  {
    g_name;
    g_exported = false;
    g_rows;
    g_title;
    g_state = List.rev !state;
    g_fill = !fill;
    g_border = !border;
    g_slots = List.rev !slots;
    g_editable = List.rev !editable;
    g_paginate = !paginate;
    g_refresh = !refresh;
    g_on_open = !on_open;
    g_on_close = !on_close;
    g_on_click = !on_click;
    g_pos;
  }
