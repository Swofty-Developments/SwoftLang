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
      (* record-valued field: 'attributes: {' is canonical, bare 'attributes {'
         is accepted as legacy (design: value-bearing block fields take a colon) *)
      ignore (matches st Token.COLON);
      attributes := parse_kv_block st ~what:"attribute"
    | Token.IDENT "tags" ->
      ignore (advance st);
      if !tags <> [] then dup "tags";
      (* nested NBT: values may be scalars, '[ ... ]' lists, or '{ ... }'
         compounds (design 9 §2). parse_packet_fields is the nested-capable
         key:value reader shared with 'send packet'. *)
      (* record-valued field: 'tags: {' is canonical, bare 'tags {' legacy *)
      ignore (matches st Token.COLON);
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

(* a typed mob tag block: '{ name: <Type> | name: <value>, ... }'. A field whose
   value position looks like a type (map/list/optional/either or a known type
   name) is a TYPE declaration (an empty, typed, indexable tag store); otherwise
   it is an item-style value init whose type is inferred (W-viewers §2). *)
let looks_like_type st =
  match peek_tok st with
  | Token.EITHER -> true
  | Token.IDENT ("optional" | "list" | "map") -> peek2_tok st = Token.LT
  | Token.IDENT name -> Parse_type.base_of_name name <> None && peek2_tok st <> Token.LPAREN
  | _ -> false

let parse_mob_tags st =
  expect st Token.LBRACE "'{' after 'tags'";
  let entries = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    let mt_pos = pos_here st in
    let mt_name = expect_ident st "tag name" in
    expect st Token.COLON "':' after tag name";
    let mt_spec =
      if looks_like_type st then MTType (Parse_type.parse_type st)
      else MTValue (parse_expr st)
    in
    entries := { mt_name; mt_pos; mt_spec } :: !entries;
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close tags block";
  List.rev !entries

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
  let viewable = ref None in
  let tags = ref [] in
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
    | Token.IDENT "viewable" ->
      ignore (advance st);
      expect st Token.COLON "':' after 'viewable'";
      if !viewable <> None then dup "viewable";
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
    | Token.IDENT "tags" ->
      ignore (advance st);
      if !tags <> [] then dup "tags";
      (* record-valued field: 'tags: {' is canonical, bare 'tags {' legacy *)
      ignore (matches st Token.COLON);
      tags := parse_mob_tags st
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
    mb_viewable = !viewable;
    mb_tags = !tags;
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

(* --- W-blocks: block_handler / placement_rule declarations ---

   A callback: 'name(binder, ...) [-> Type] { body }'. The binder names are
   user-chosen; the parameter and return types are fixed by the callback name
   (validated in Tc_decl). The written '-> Type' is optional and, when present,
   recorded for the checker to cross-check against the fixed return type. *)
let parse_block_cb st =
  let cb_pos = pos_here st in
  let cb_name = expect_ident st "callback name" in
  expect st Token.LPAREN "'(' after callback name";
  let params = ref [] in
  if peek_tok st <> Token.RPAREN then begin
    let one () =
      let pp = pos_here st in
      (expect_ident st "callback parameter name", pp)
    in
    params := [ one () ];
    while matches st Token.COMMA do
      params := one () :: !params
    done
  end;
  expect st Token.RPAREN "')' to close the callback parameter list";
  let cb_ret = if matches st Token.ARROW then Some (Parse_type.parse_type st) else None in
  let cb_body = parse_body st in
  { cb_name; cb_params = List.rev !params; cb_ret; cb_body; cb_pos }

let parse_block_handler st =
  let bh_pos = pos_here st in
  ignore (advance st);
  (* 'block_handler' *)
  let bh_id = expect_string st "block id after 'block_handler'" in
  expect st Token.LBRACE "'{' after block_handler id";
  let cbs = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    cbs := parse_block_cb st :: !cbs
  done;
  expect st Token.RBRACE "'}' to close block_handler body";
  { bh_id; bh_callbacks = List.rev !cbs; bh_pos }

let parse_placement_rule st =
  let pr_pos = pos_here st in
  ignore (advance st);
  (* 'placement_rule' *)
  expect_soft st "for";
  let pr_id = expect_string st "block id after 'placement_rule for'" in
  expect st Token.LBRACE "'{' after placement_rule id";
  let cbs = ref [] in
  let self_replaceable = ref false in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "self_replaceable" when peek2_tok st = Token.COLON ->
      ignore (advance st);
      ignore (advance st);
      (match peek_tok st with
      | Token.TRUE ->
        ignore (advance st);
        self_replaceable := true
      | Token.FALSE ->
        ignore (advance st);
        self_replaceable := false
      | t ->
        error st
          (Printf.sprintf "Expected 'true' or 'false' after 'self_replaceable:', found %s"
             (Token.describe t)))
    | _ -> cbs := parse_block_cb st :: !cbs);
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close placement_rule body";
  { pr_id; pr_callbacks = List.rev !cbs; pr_self_replaceable = !self_replaceable; pr_pos }

(* --- OOP receiver blocks ---

   `Player { on_join() {} on_death(killer) {} }` — a Capitalized base-type block
   whose members are fixed-name methods, parsed with the same inline-handler
   grammar as the item/mob additive handlers. Method names are validated against
   the receiver's table in Tc_decl. *)
let parse_receiver st =
  let rc_pos = pos_here st in
  let rc_type_pos = pos_here st in
  let rc_type = expect_ident st "receiver type name" in
  expect st Token.LBRACE "'{' after receiver type name";
  let methods = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    let h = parse_inline_handler st in
    if List.exists (fun (x : inline_handler) -> x.ih_event = h.ih_event) !methods then
      error st (Printf.sprintf "Duplicate %s method '%s'" rc_type h.ih_event);
    methods := h :: !methods;
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close receiver body";
  { rc_type; rc_type_pos; rc_methods = List.rev !methods; rc_pos }

(* `Packet { on "PacketClassName" { body } on "Other" { body } }` — the OOP
   spelling of the packet-listener subsystem. Each `on "Class" { body }` member
   desugars into a packet_listener (reusing the exact runtime path); the body is
   the handler's statements directly (no nested 'execute { }'). *)
let parse_packet_receiver st =
  ignore (advance st);
  (* 'Packet' *)
  expect st Token.LBRACE "'{' after 'Packet'";
  let listeners = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    (match peek_tok st with
    | Token.IDENT "on" ->
      let pk_pos = pos_here st in
      ignore (advance st);
      (* 'on' *)
      let pk_name = expect_string st "packet class name after 'on'" in
      let ex_stmts = parse_body st in
      listeners :=
        { pk_name; pk_execute = Some { ex_async = false; ex_stmts }; pk_pos } :: !listeners
    | t ->
      error st
        (Printf.sprintf "Expected 'on \"PacketClassName\" { }' inside 'Packet { }', found %s"
           (Token.describe t)));
    ignore (matches st Token.COMMA)
  done;
  expect st Token.RBRACE "'}' to close 'Packet' body";
  List.rev !listeners
