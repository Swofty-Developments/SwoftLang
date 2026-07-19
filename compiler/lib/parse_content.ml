(* Phase-5 content declarations: item "id" { }, mob "id" { }, on packet "Name" { } *)

open Ast
open Parser_state
open Parse_expr
open Parse_stmt
open Parse_decl

(* key: expr pairs, comma-optional; used by the item attributes { } block *)
let parse_kv_block st ~what =
  expect st Token.LBRACE (Printf.sprintf "'{' after '%s'" what);
  let entries = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    let kpos = pos_here st in
    let key = expect_ident st (Printf.sprintf "%s name" what) in
    expect st Token.COLON (Printf.sprintf "':' after %s name" what);
    entries := (key, kpos, parse_expr st) :: !entries;
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE (Printf.sprintf "'}' to close %s block" what);
  List.rev !entries

(* phase-9: the removed Hypixel-flavor blocks. stats{}/ability{} are no longer
   language constructs — gameplay systems are userland (event handlers or an
   addon). Naming the block points the scripter at the migration path. *)
let removed_block_error st what =
  error st
    (Printf.sprintf
       "'%s' blocks were removed in SwoftLang: define gameplay systems with event handlers or an \
        addon (see docs/items)"
       what)

(* on_click(<filter>) sugar filters: use-item interactions only *)
let item_click_filters = [ "left"; "right"; "any" ]

let parse_item_decl st =
  let it_pos = pos_here st in
  ignore (advance st);
  let it_id = expect_string st "item id" in
  expect st Token.LBRACE "'{' after item id";
  let material = ref None in
  let skull = ref None in
  let name = ref None in
  let rarity = ref None in
  let glint = ref None in
  let amount = ref None in
  let lore = ref None in
  let attributes = ref [] in
  let tags = ref [] in
  let on_click = ref [] in
  let handlers = ref [] in
  let dup field = error st (Printf.sprintf "Duplicate item field '%s'" field) in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "material" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'material'";
      if !material <> None then dup "material";
      material := Some (expect_string st "material name")
    | Token.IDENT "skull" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'skull'";
      if !skull <> None then dup "skull";
      skull := Some (expect_string st "skull texture")
    | Token.IDENT "name" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'name'";
      if !name <> None then dup "name";
      name := Some (parse_expr st)
    | Token.IDENT "rarity" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'rarity'";
      if !rarity <> None then dup "rarity";
      let rpos = pos_here st in
      rarity := Some (expect_ident st "rarity name", rpos)
    | Token.IDENT "glint" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'glint'";
      if !glint <> None then dup "glint";
      glint := Some (parse_expr st)
    | Token.IDENT "amount" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'amount'";
      if !amount <> None then dup "amount";
      amount := Some (parse_expr st)
    | Token.IDENT "lore" ->
      ignore (advance st);
      if !lore <> None then dup "lore";
      let block = parse_dsl_block st DslLines in
      (match block.s with
      | SBlock ss -> lore := Some ss
      | _ -> ())
    | Token.IDENT "attributes" ->
      ignore (advance st);
      if !attributes <> [] then dup "attributes";
      attributes := parse_kv_block st ~what:"attribute"
    | Token.IDENT "tags" ->
      ignore (advance st);
      if !tags <> [] then dup "tags";
      (* nested NBT: values may be scalars, '[ ... ]' lists, or '{ ... }'
         compounds (design 9 §2). parse_packet_fields is the nested-capable
         key:value reader shared with 'send packet'. *)
      expect st Token.LBRACE "'{' after 'tags'";
      tags := parse_packet_fields st;
      expect st Token.RBRACE "'}' to close tags block"
    | Token.IDENT "on_click" ->
      ignore (advance st);
      let ch_filter =
        if matches st Token.LPAREN then begin
          let fpos = pos_here st in
          let f = expect_ident st "on_click filter" in
          if not (List.mem f item_click_filters) then
            (ignore fpos;
             error st
               (Printf.sprintf "Unknown on_click filter '%s'; valid filters: left, right, any" f));
          expect st Token.RPAREN "')' after on_click filter";
          f
        end
        else "any"
      in
      on_click := { ch_filter; ch_body = parse_body st } :: !on_click
    | Token.IDENT "stats" -> removed_block_error st "stats"
    | Token.IDENT "ability" -> removed_block_error st "ability"
    (* generic first-class handlers (on_click is the filter sugar above and is
       matched first; every other on_<name> flows here) *)
    | Token.IDENT name when starts_with_on name ->
      let h = parse_inline_handler st in
      if List.exists (fun (x : inline_handler) -> x.ih_event = h.ih_event) !handlers then
        error st (Printf.sprintf "Duplicate handler '%s'" h.ih_event);
      handlers := h :: !handlers
    | t -> error st (Printf.sprintf "Unknown item property: %s" (Token.describe t)));
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close item body";
  {
    it_id;
    it_exported = false;
    it_material = !material;
    it_skull = !skull;
    it_name = !name;
    it_rarity = !rarity;
    it_glint = !glint;
    it_amount = !amount;
    it_lore = !lore;
    it_attributes = !attributes;
    it_tags = !tags;
    it_on_click = List.rev !on_click;
    it_handlers = List.rev !handlers;
    it_pos;
  }

let parse_drops st =
  expect st Token.LBRACE "'{' after 'drops'";
  let drops = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    expect_soft st "item";
    let dr_pos = pos_here st in
    let dr_id = expect_string st "item id in drops" in
    expect_soft st "chance";
    let dr_chance = parse_expr st in
    let dr_amount = if eat_soft st "amount" then Some (parse_expr st) else None in
    drops := { dr_id; dr_pos; dr_chance; dr_amount } :: !drops
  done;
  expect st Token.RBRACE "'}' to close drops block";
  List.rev !drops

let parse_mob_decl st =
  let mb_pos = pos_here st in
  ignore (advance st);
  let mb_id = expect_string st "mob id" in
  expect st Token.LBRACE "'{' after mob id";
  let typ = ref None in
  let name = ref None in
  let health = ref None in
  let damage = ref None in
  let speed = ref None in
  let ai = ref None in
  let drops = ref [] in
  let on_spawn = ref None in
  let on_death = ref None in
  let on_attack = ref None in
  let on_hit = ref None in
  let handlers = ref [] in
  let dup field = error st (Printf.sprintf "Duplicate mob field '%s'" field) in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "type" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'type'";
      if !typ <> None then dup "type";
      let tpos = pos_here st in
      typ := Some (expect_string st "entity type name", tpos)
    | Token.IDENT "name" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'name'";
      if !name <> None then dup "name";
      name := Some (parse_expr st)
    | Token.IDENT "health" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'health'";
      if !health <> None then dup "health";
      health := Some (parse_expr st)
    | Token.IDENT "damage" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'damage'";
      if !damage <> None then dup "damage";
      damage := Some (parse_expr st)
    | Token.IDENT "speed" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'speed'";
      if !speed <> None then dup "speed";
      speed := Some (parse_expr st)
    | Token.IDENT "ai" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'ai'";
      if !ai <> None then dup "ai";
      let apos = pos_here st in
      ai := Some (expect_ident st "ai mode", apos)
    | Token.IDENT "drops" ->
      ignore (advance st);
      if !drops <> [] then dup "drops";
      drops := parse_drops st
    | Token.IDENT "on_spawn" ->
      ignore (advance st);
      if !on_spawn <> None then dup "on_spawn";
      on_spawn := Some (parse_body st)
    | Token.IDENT "on_death" ->
      ignore (advance st);
      if !on_death <> None then dup "on_death";
      on_death := Some (parse_body st)
    | Token.IDENT "on_attack" ->
      ignore (advance st);
      if !on_attack <> None then dup "on_attack";
      on_attack := Some (parse_body st)
    | Token.IDENT "on_hit" ->
      ignore (advance st);
      if !on_hit <> None then dup "on_hit";
      (* on_hit(attacker) { }: the parenthesized identifier is the binder for the
         attacking player (optional<Player>) *)
      expect st Token.LPAREN "'(' after 'on_hit'";
      let attacker = expect_ident st "attacker binder in on_hit(...)" in
      expect st Token.RPAREN "')' after on_hit attacker binder";
      on_hit := Some (attacker, parse_body st)
    (* generic first-class handlers: on_click / on_attack / on_target / on_tick.
       on_spawn/on_death/on_attack/on_hit are matched by dedicated branches
       above and never reach here. *)
    | Token.IDENT name when starts_with_on name ->
      let h = parse_inline_handler st in
      if List.exists (fun (x : inline_handler) -> x.ih_event = h.ih_event) !handlers then
        error st (Printf.sprintf "Duplicate handler '%s'" h.ih_event);
      handlers := h :: !handlers
    | t -> error st (Printf.sprintf "Unknown mob property: %s" (Token.describe t)));
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close mob body";
  if !typ = None then error st (Printf.sprintf "mob \"%s\" requires 'type:'" mb_id);
  {
    mb_id;
    mb_exported = false;
    mb_type = !typ;
    mb_name = !name;
    mb_health = !health;
    mb_damage = !damage;
    mb_speed = !speed;
    mb_ai = !ai;
    mb_drops = !drops;
    mb_on_spawn = !on_spawn;
    mb_on_death = !on_death;
    mb_on_attack = !on_attack;
    mb_on_hit = !on_hit;
    mb_handlers = List.rev !handlers;
    mb_pos;
  }

(* --- phase-8 fishing loot tables ---

   fishing_loot "name" {
     medium: water            // water | lava (required)
     world: "overworld"       // optional world-name match
     catch item "COD" weight 40
     catch mob "sea_walker" weight 3
     catch item "PUFFERFISH" weight 10 message "<yellow>Woah!"
   } *)
let parse_fishing_catch st =
  let fc_pos = pos_here st in
  ignore (advance st);
  (* 'catch' *)
  let fc_mob =
    match peek_tok st with
    | Token.IDENT "item" ->
      ignore (advance st);
      false
    | Token.IDENT "mob" ->
      ignore (advance st);
      true
    | t ->
      error st (Printf.sprintf "Expected 'item' or 'mob' after 'catch', found %s"
                  (Token.describe t))
  in
  let fc_id = expect_string st "catch id" in
  expect_soft st "weight";
  let fc_weight = parse_expr st in
  let fc_message = if eat_soft st "message" then Some (expect_string st "catch message") else None in
  { fc_mob; fc_id; fc_weight; fc_message; fc_pos }

let parse_fishing_loot st =
  let fl_pos = pos_here st in
  ignore (advance st);
  (* 'fishing_loot' *)
  let fl_name = expect_string st "fishing_loot name" in
  expect st Token.LBRACE "'{' after fishing_loot name";
  let medium = ref None in
  let world = ref None in
  let catches = ref [] in
  let dup field = error st (Printf.sprintf "Duplicate fishing_loot field '%s'" field) in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "medium" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'medium'";
      if !medium <> None then dup "medium";
      let mpos = pos_here st in
      medium := Some (expect_ident st "fishing medium", mpos)
    | Token.IDENT "world" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'world'";
      if !world <> None then dup "world";
      world := Some (expect_string st "world name")
    | Token.IDENT "catch" -> catches := parse_fishing_catch st :: !catches
    | t -> error st (Printf.sprintf "Unknown fishing_loot property: %s" (Token.describe t)));
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close fishing_loot body";
  if !medium = None then
    error st (Printf.sprintf "fishing_loot \"%s\" requires 'medium:' (water or lava)" fl_name);
  {
    fl_name;
    fl_medium = !medium;
    fl_world = !world;
    fl_catches = List.rev !catches;
    fl_pos;
  }

(* api "/path/:param" { method: GET, execute { ... } } (design 6B) *)
let parse_api_decl st =
  let api_pos = pos_here st in
  ignore (advance st);
  (* 'api' *)
  let api_path = expect_string st "api path" in
  expect st Token.LBRACE "'{' after api path";
  let meth = ref None in
  let execute = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "method" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'method'";
      let mpos = pos_here st in
      meth := Some (expect_ident st "http method", mpos)
    | Token.IDENT "execute" ->
      ignore (advance st);
      execute := Some (parse_execute st)
    | t -> error st (Printf.sprintf "Unknown api property: %s" (Token.describe t)));
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close api body";
  { api_path; api_method = !meth; api_execute = !execute; api_pos }

(* top-level 'every <duration> { body }' scheduler (design 6D) *)
let parse_sched_decl st =
  let sd_pos = pos_here st in
  ignore (advance st);
  (* 'every' *)
  let sd_every = parse_duration st in
  let sd_name =
    if matches st Token.AS then Some (expect_string st "scheduler name after 'as'") else None
  in
  let sd_body = parse_body st in
  { sd_every; sd_name; sd_body; sd_pos }

let parse_packet_listener st =
  let pk_pos = pos_here st in
  ignore (advance st);
  (* 'on' *)
  ignore (advance st);
  (* 'packet' *)
  let pk_name = expect_string st "packet class name" in
  expect st Token.LBRACE "'{' after packet name";
  let execute = ref None in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    match peek_tok st with
    | Token.IDENT "execute" ->
      ignore (advance st);
      execute := Some (parse_execute st)
    | t -> error st (Printf.sprintf "Expected 'execute' in 'on packet' body, found %s"
                       (Token.describe t))
  done;
  expect st Token.RBRACE "'}' to close 'on packet' body";
  { pk_name; pk_execute = !execute; pk_pos }
