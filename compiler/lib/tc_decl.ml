open Ast
open Registry
open Tc_types
open Tc_env
open Tc_expr
open Tc_stmt
open Tc_registry_checks

let base_gui_env = bind (bind empty_env "player" TPlayer) "state" TAny

let check_item_spec ctx bctx env spec =
  (match (spec.is_material, spec.is_skull) with
  | Some _, Some _ -> err ctx spec.is_pos "item cannot have both 'material' and 'skull'"
  | None, None -> err ctx spec.is_pos "item requires either 'material' or 'skull'"
  | _ -> ());
  let field use e =
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use;
    t
  in
  (match spec.is_material with
  | Some e -> (
    match field "the item material" e with
    | TString | TAny -> ()
    | t -> err ctx e.epos "item material must be a String (got %s)" (ty_to_string t))
  | None -> ());
  (match spec.is_skull with
  | Some e -> ignore (field "the item skull" e)
  | None -> ());
  (match spec.is_name with
  | Some e -> ignore (field "the item name" e)
  | None -> ());
  (match spec.is_lore with
  | Some items -> List.iter (fun e -> ignore (field "an item lore line" e)) items
  | None -> ());
  (match spec.is_amount with
  | Some e ->
    let t = field "the item amount" e in
    if not (num_ok t) then err ctx e.epos "item amount must be a number (got %s)" (ty_to_string t)
  | None -> ());
  match spec.is_glint with
  | Some e ->
    let t = field "the item glint" e in
    if not (boolish t) then err ctx e.epos "item glint must be a Boolean (got %s)" (ty_to_string t)
  | None -> ()

let check_gui ctx g =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  List.iter
    (fun b ->
      if Hashtbl.mem ctx.persists b then
        err ctx g.g_pos
          "persistent '%s' shadows the built-in gui binding '%s' — rename the persistent" b b)
    [ "state"; "slot"; "click_type"; "index"; "old_item"; "new_item"; "reason" ];
  if g.g_rows < 1 || g.g_rows > 6 then
    err ctx g.g_pos "gui '%s' rows must be between 1 and 6 (got %d)" g.g_name g.g_rows;
  let max_slot = (g.g_rows * 9) - 1 in
  let check_slots pos slots =
    List.iter
      (fun s ->
        if s < 0 || s > max_slot then
          err ctx pos "slot %d is out of range for %d row(s) (0..%d)" s g.g_rows max_slot)
      slots
  in
  let env = base_gui_env in
  List.iter
    (fun (_, e) ->
      let t = type_of ctx bctx env e in
      require_present ctx env e t ~use:"the initial state value")
    g.g_state;
  let tt = type_of ctx bctx env g.g_title in
  require_present ctx env g.g_title tt ~use:"the gui title";
  let check_fill = function
    | Some (FSpec spec) -> check_item_spec ctx bctx env spec
    | Some (FExpr e) -> (
      let t = type_of ctx bctx env e in
      require_present ctx env e t ~use:"the fill item";
      match t with
      | TItem | TAny -> ()
      | _ -> err ctx e.epos "fill/border must be an Item (got %s)" (ty_to_string t))
    | None -> ()
  in
  check_fill g.g_fill;
  check_fill g.g_border;
  (match g.g_refresh with
  | Some r when r <= 0 -> err ctx g.g_pos "refresh interval must be positive"
  | _ -> ());
  List.iter
    (fun slot ->
      check_slots slot.gs_pos slot.gs_slots;
      check_item_spec ctx bctx env slot.gs_item;
      (match slot.gs_refresh with
      | Some r when r <= 0 -> err ctx slot.gs_pos "refresh interval must be positive"
      | _ -> ());
      List.iter
        (fun ch ->
          let henv = bind (bind env "slot" TInteger) "click_type" TString in
          ignore (check_stmts ctx bctx henv ch.ch_body))
        slot.gs_clicks)
    g.g_slots;
  List.iter
    (fun ed ->
      check_slots ed.ge_pos ed.ge_slots;
      match ed.ge_on_change with
      | Some body ->
        let henv =
          bind (bind (bind env "slot" TInteger) "old_item" TItem) "new_item" TItem
        in
        ignore (check_stmts ctx bctx henv body)
      | None -> ())
    g.g_editable;
  (match g.g_paginate with
  | Some pg ->
    let src_t = type_of ctx bctx env pg.gp_source in
    require_present ctx env pg.gp_source src_t ~use:"the paginate source";
    let elem =
      match src_t with
      | TList t -> t
      | TAny -> TAny
      | _ ->
        err ctx pg.gp_source.epos "paginate source must be a list (got %s)" (ty_to_string src_t);
        TAny
    in
    check_slots pg.gp_pos pg.gp_slots;
    (match pg.gp_prev_slot with
    | Some s -> check_slots pg.gp_pos [ s ]
    | None -> ());
    (match pg.gp_next_slot with
    | Some s -> check_slots pg.gp_pos [ s ]
    | None -> ());
    let penv = bind (bind env "item" elem) "index" TInteger in
    check_item_spec ctx bctx penv pg.gp_render;
    (match pg.gp_on_click with
    | Some body -> ignore (check_stmts ctx bctx penv body)
    | None -> ())
  | None -> ());
  (match g.g_on_open with
  | Some body -> ignore (check_stmts ctx bctx env body)
  | None -> ());
  (match g.g_on_close with
  | Some body -> ignore (check_stmts ctx bctx (bind env "reason" TString) body)
  | None -> ());
  match g.g_on_click with
  | Some body ->
    let henv = bind (bind env "slot" TInteger) "click_type" TString in
    ignore (check_stmts ctx bctx henv body)
  | None -> ()

let check_function ctx f =
  List.iter (fun p -> check_persist_shadow ctx p.p_pos "parameter" p.p_name) f.params;
  let fsig = Hashtbl.find ctx.funcs f.fn_name in
  let vals = ref [] in
  let bare = ref false in
  let bctx =
    {
      color = (if f.fn_async then Async else Sync);
      event = None;
      args = None;
      ret_sink = Some (vals, bare);
      packet = false;
      api = false;
      in_schedule = false;
      override = None;
    }
  in
  let env =
    List.fold_left
      (fun env (name, ty) -> bind env name ty)
      (bind (base_env ctx) "sender" TPlayer)
      fsig.f_params
  in
  let _, terminates = check_stmts ctx bctx env f.body in
  let ret =
    match !vals with
    | [] -> TAny
    | t :: rest ->
      let joined = List.fold_left join t rest in
      if !bare || not terminates then wrap_optional joined else joined
  in
  fsig.f_ret <- ret

let check_command ctx c =
  List.iter (fun a -> check_persist_shadow ctx a.arg_pos "argument" a.arg_name) c.arguments;
  let args = List.map (fun a -> (a.arg_name, ty_of_dt a.arg_type)) c.arguments in
  match c.execute with
  | None -> ()
  | Some ex ->
    let bctx =
      {
        color = (if ex.ex_async then Async else Sync);
        event = None;
        args = Some args;
        ret_sink = None;
        packet = false;
        api = false;
        in_schedule = false;
        override = None;
      }
    in
    (* args are also stored unprefixed in the runtime variables map *)
    let env =
      List.fold_left
        (fun env (name, ty) -> bind env name ty)
        (bind (base_env ctx) "sender" TPlayer)
        args
    in
    ignore (check_stmts ctx bctx env ex.ex_stmts)

let check_scoreboard ctx sb =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  let env = bind empty_env "player" TPlayer in
  let tt = type_of ctx bctx env sb.sb_title in
  require_present ctx env sb.sb_title tt ~use:"the scoreboard title";
  (match sb.sb_update with
  | UTicks n when n <= 0 -> err ctx sb.sb_pos "update cadence must be positive"
  | _ -> ());
  ignore (check_stmts ctx bctx env sb.sb_lines);
  let n = count_units `Lines sb.sb_lines in
  if n > sidebar_max_lines then
    err ctx sb.sb_pos
      "scoreboard '%s' can emit %d lines on a static path; the sidebar limit is %d" sb.sb_name n
      sidebar_max_lines

let check_tablist ctx tl =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  let env = bind empty_env "player" TPlayer in
  (match tl.tl_update with
  | UTicks n when n <= 0 -> err ctx tl.tl_pos "update cadence must be positive"
  | _ -> ());
  (match tl.tl_header with
  | Some e ->
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use:"the tablist header"
  | None -> ());
  (match tl.tl_footer with
  | Some e ->
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use:"the tablist footer"
  | None -> ());
  List.iter
    (fun col ->
      ignore (check_stmts ctx bctx env col.col_body);
      let n = count_units `Column col.col_body in
      if n > tablist_column_max_entries then
        err ctx col.col_pos
          "tablist column can emit %d entries on a static path; the client limit is %d per column"
          n tablist_column_max_entries)
    tl.tl_columns

let check_bossbar ctx bb =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  let env = bind empty_env "player" TPlayer in
  let tt = type_of ctx bctx env bb.bb_text in
  require_present ctx env bb.bb_text tt ~use:"the bossbar text";
  let pt = type_of ctx bctx env bb.bb_progress in
  require_present ctx env bb.bb_progress pt ~use:"the bossbar progress";
  if not (num_ok pt) then
    err ctx bb.bb_progress.epos "bossbar progress must be a number (got %s)" (ty_to_string pt);
  if not (List.mem bb.bb_color bossbar_colors) then
    err ctx bb.bb_pos "unknown bossbar color '%s'; valid colors: %s%s" bb.bb_color
      (String.concat ", " bossbar_colors)
      (suggestion bb.bb_color bossbar_colors);
  if not (List.mem bb.bb_style bossbar_styles) then
    err ctx bb.bb_pos "unknown bossbar style '%s'; valid styles: %s%s" bb.bb_style
      (String.concat ", " bossbar_styles)
      (suggestion bb.bb_style bossbar_styles);
  match bb.bb_update with
  | UTicks n when n <= 0 -> err ctx bb.bb_pos "update cadence must be positive"
  | _ -> ()

let check_storages ctx storages =
  (match storages with
  | [] | [ _ ] -> ()
  | _ :: rest ->
    List.iter
      (fun (s : storage_conf) ->
        err ctx s.st_pos
          "duplicate 'storage' block; only one storage block is allowed per script")
      rest);
  List.iter
    (fun (s : storage_conf) ->
      if s.st_flush_ticks <= 0 then err ctx s.st_pos "flush cadence must be positive")
    storages

let register_persistent ctx (pd : persistent_decl) =
  if Hashtbl.mem ctx.persists pd.pd_name then
    err ctx pd.pd_pos "duplicate persistent '%s'" pd.pd_name
  else begin
    if Hashtbl.mem ctx.funcs pd.pd_name then
      err ctx pd.pd_pos "persistent '%s' collides with function '%s'" pd.pd_name pd.pd_name;
    if find_builtin pd.pd_name <> None then
      err ctx pd.pd_pos "persistent '%s' collides with the builtin function '%s'" pd.pd_name
        pd.pd_name;
    if List.mem pd.pd_name [ "sender"; "event"; "args" ] then
      err ctx pd.pd_pos "persistent '%s' collides with the built-in '%s' binding — pick another \
                         name"
        pd.pd_name pd.pd_name;
    (* the '__' prefix is reserved for internal stores (e.g. __seen_players,
       the seen-players record) that ride the same storage backend: a user
       persistent with that name would corrupt the internal data *)
    if String.length pd.pd_name >= 2 && String.sub pd.pd_name 0 2 = "__" then
      err ctx pd.pd_pos "persistent '%s' uses the reserved '__' name prefix (internal stores such \
                         as __seen_players live there) — pick another name"
        pd.pd_name;
    Hashtbl.add ctx.persists pd.pd_name
      {
        pi_subject = Option.map (resolve_ty ctx) pd.pd_subject;
        pi_ty = resolve_ty ctx pd.pd_type;
      }
  end

(* W-persist: the value types that persist cleanly. Each has a total value
   serialization (JSON on the backend): the scalars plus Location, Vec and
   Item (via to_nbt/from_nbt). Player/Entity are live handles and are rejected
   with an actionable hint. *)
let persistable_value = function
  | TString | TInteger | TDouble | TBoolean | TLocation | TVec | TItem -> true
  | _ -> false

(* value types that persist inside a persistent CONTAINER position (a list
   element, an optional inner, or a map value): the persistable scalars, PLUS
   Player / OfflinePlayer which serialize by uuid and rehydrate by uuid
   (resolve-or-cull on load, per the entity-ref rule — an offline Player drops
   from a list / reads back as none). Base Entity/Mob are excluded: they are not
   uuid-stable snapshots and stay rejected as values. A BARE Player is likewise
   still rejected at top level (there is no none/default to cull an unresolvable
   uuid to); only the container positions admit it. *)
let persist_elem_value = function
  | TPlayer | TOfflinePlayer -> true
  | t -> persistable_value t

(* §3.2 struct serializability: a struct may be persistent iff every field is a
   serializable type. The serializable set for struct fields is a superset of
   the top-level persistable values: it additionally admits Player /
   OfflinePlayer (serialized by uuid) and nested serializable structs. The walk
   is cycle-guarded (a struct that reaches itself is assumed fine — its concrete
   leaves were checked on the way in). *)
let rec serializable_ty ctx ~seen ty =
  match ty with
  | TString | TInteger | TDouble | TBoolean | TLocation | TVec | TItem | TPlayer | TOfflinePlayer
    ->
    true
  | TOptional t | TList t -> serializable_ty ctx ~seen t
  | TMap ((TString | TInteger | TPlayer), v) -> serializable_ty ctx ~seen v
  | TStruct n ->
    List.mem n seen
    ||
    (match Hashtbl.find_opt ctx.structs n with
    | Some si -> List.for_all (fun (_, t) -> serializable_ty ctx ~seen:(n :: seen) t) si.si_fields
    | None -> true)
  | _ -> false

(* the first field of struct `n` whose type is not serializable, for the
   persistence diagnostic (names the offending direct field). *)
let first_nonserializable_field ctx n =
  match Hashtbl.find_opt ctx.structs n with
  | None -> None
  | Some si -> List.find_opt (fun (_, t) -> not (serializable_ty ctx ~seen:[ n ] t)) si.si_fields

(* §3.2/§4 reactive serializability: for a reactive struct a live-entity handle
   field (Entity/Mob and the nominal custom types) persists by uuid and is
   resolve-or-cull on load, so it counts as serializable — this is exactly the
   subject a struct reacts on (`boss: Mob` handlers) and the plain data handles
   §4.4 permits (`leader: Mob`). Every other field falls back to the standard
   persistence predicate (so World/Schedule/Canvas etc. are still rejected). *)
let rec reactive_serializable_ty ctx ~seen ty =
  match ty with
  | TEntity | TMob | TCustomMob _ | TCustomItem _ -> true
  | TOptional t | TList t -> reactive_serializable_ty ctx ~seen t
  | TMap ((TString | TInteger | TPlayer), v) -> reactive_serializable_ty ctx ~seen v
  | TStruct n ->
    List.mem n seen
    ||
    (match Hashtbl.find_opt ctx.structs n with
    | Some si ->
      List.for_all (fun (_, t) -> reactive_serializable_ty ctx ~seen:(n :: seen) t) si.si_fields
    | None -> true)
  | other -> serializable_ty ctx ~seen other

let first_reactive_nonserializable_field ctx n =
  match Hashtbl.find_opt ctx.structs n with
  | None -> None
  | Some si ->
    List.find_opt (fun (_, t) -> not (reactive_serializable_ty ctx ~seen:[ n ] t)) si.si_fields

let check_persistent ctx (pd : persistent_decl) =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  let declared = resolve_ty ctx pd.pd_type in
  (* the struct at the value leaf of the declared type, if any — for the
     serializability diagnostic that names the offending field *)
  let struct_leaf =
    match declared with
    | TStruct n | TOptional (TStruct n) | TList (TStruct n) | TMap (_, TStruct n) -> Some n
    | _ -> None
  in
  let reject_live () =
    err ctx pd.pd_pos
      "persistent '%s' cannot store a live Player/Entity value; persist the uuid (String) or a \
       respawnable snapshot"
      pd.pd_name
  in
  (match declared with
  (* §3.2 a struct (or optional/list/map of one) is persistent iff all its
     fields are serializable; otherwise name the offending field *)
  | (TStruct _ | TOptional (TStruct _) | TList (TStruct _) | TMap (_, TStruct _))
    when (match struct_leaf with Some n -> serializable_ty ctx ~seen:[] (TStruct n) | None -> false)
    ->
    ()
  | TStruct _ | TOptional (TStruct _) | TList (TStruct _) | TMap (_, TStruct _) -> (
    match struct_leaf with
    | Some n -> (
      match first_nonserializable_field ctx n with
      | Some (fn, ft) ->
        err ctx pd.pd_pos
          "persistent '%s' cannot store struct '%s': field '%s' has non-serializable type %s"
          pd.pd_name n fn (ty_to_string ft)
      | None ->
        err ctx pd.pd_pos "persistent '%s' cannot store struct '%s' (a field is non-serializable)"
          pd.pd_name n)
    | None -> ())
  (* bare persistable value (scalar/Location/Vec/Item — not a bare Player) *)
  | t when persistable_value t -> ()
  (* an optional/list whose element is a persistable value OR Player /
     OfflinePlayer (serialized by uuid, resolve-or-cull on load) *)
  | TOptional t when persist_elem_value t -> ()
  | TList t when persist_elem_value t -> ()
  (* phase 10: a persistent may be a map keyed by String, Integer or Player
     (Player serialized by uuid on the Java side); values may be any persistable
     value type, plus Player / OfflinePlayer (also serialized by uuid).
     Serialized as JSON to the backend. *)
  | TMap ((TString | TInteger | TPlayer), v) when persist_elem_value v -> ()
  (* live handles that stay rejected as VALUES: a bare Player (no none/default to
     cull an unresolvable uuid to) and Entity in every position (not a uuid-
     stable snapshot). Player/OfflinePlayer in a list/optional/map value are
     accepted above; Mob/other non-uuid handles fall through to the errors
     below. *)
  | TPlayer | TEntity
  | TOptional TEntity
  | TList TEntity
  | TMap (_, TEntity) ->
    reject_live ()
  | TMap ((TString | TInteger | TPlayer), v) ->
    err ctx pd.pd_pos
      "persistent '%s' map values must be a persistable value type (String, Integer, Double, \
       Boolean, Location, Vec, or Item), got %s"
      pd.pd_name (ty_to_string v)
  | TMap (k, _) ->
    err ctx pd.pd_pos
      "persistent '%s' must be keyed by String, Integer, or Player, got map key type %s"
      pd.pd_name (ty_to_string k)
  | t ->
    err ctx pd.pd_pos
      "persistent '%s' must be a persistable value type (String, Integer, Double, Boolean, \
       Location, Vec, Item), or a list/map/optional of those, got %s"
      pd.pd_name (ty_to_string t));
  let dt = type_of ctx bctx empty_env pd.pd_default in
  (* an optional-typed persistent legitimately defaults to `none`; only require
     a present value for non-optional declared types *)
  (match declared with
  | TOptional _ -> ()
  | _ -> require_present ctx empty_env pd.pd_default dt ~use:"the default value");
  if not (param_compat declared dt) then
    err ctx pd.pd_default.epos "the default value of persistent '%s' must be %s (got %s)"
      pd.pd_name (ty_to_string declared) (ty_to_string dt)

(* --- phase-5 content declarations --- *)

(* item ids feed namespaced keys at runtime ("swoftlang:item/<id>/<slot>/
   <attr>" attribute-modifier ids), whose key path only permits
   [a-z0-9_.-]; anything else (e.g. SkyBlock-style UPPERCASE ids) would
   throw InvalidKeyException on every equipment scan *)
let valid_item_id id =
  String.length id > 0
  && String.for_all
       (fun c ->
         (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c = '_' || c = '.' || c = '-')
       id

(* §2 nominal custom types: publish the Capitalized type names so they resolve
   in type positions ('boss: Ghoul', 'is a Ghoul', 'spawn mob Ghoul'). Runs in
   pass 1 BEFORE any type annotation (function params, persistents, mob tags) is
   resolved, and before register_items/register_mobs validate the id tables. A
   name that collides with a builtin type or with the other kind is rejected. *)
let register_custom_types ctx (script : Ast.script) =
  let claim tbl kind (name : string) id pos =
    if Tc_types.ty_of_type_name name <> None then
      err ctx pos
        "custom %s type '%s' collides with a built-in type name — choose another name" kind name
    else if
      Hashtbl.mem ctx.custom_mobs name || Hashtbl.mem ctx.custom_items name
      || Hashtbl.mem ctx.structs name
    then err ctx pos "duplicate custom type '%s'" name
    else Hashtbl.replace tbl name id
  in
  List.iter
    (fun (mb : mob_decl) -> claim ctx.custom_mobs "mob" mb.mb_tyname mb.mb_id mb.mb_pos)
    script.mobs;
  List.iter
    (fun (it : item_decl) -> claim ctx.custom_items "item" it.it_tyname it.it_id it.it_pos)
    script.items

(* §1 structs: publish the Capitalized struct names (pass 1a), rejecting a name
   that collides with a built-in type or another custom/struct type. The name
   must be visible before any type annotation — including other structs' fields
   — resolves. Fields are filled in a second sub-pass (register_struct_fields)
   once every type name is known. *)
let register_struct_names ctx (script : Ast.script) =
  List.iter
    (fun (sd : struct_decl) ->
      let name = sd.su_tyname in
      if Tc_types.ty_of_type_name name <> None then
        err ctx sd.su_pos
          "struct type '%s' collides with a built-in type name — choose another name" name
      else if
        Hashtbl.mem ctx.custom_mobs name || Hashtbl.mem ctx.custom_items name
        || Hashtbl.mem ctx.structs name
      then err ctx sd.su_pos "duplicate custom type '%s'" name
      else Hashtbl.replace ctx.structs name { si_fields = []; si_required = []; si_reactive = [] })
    script.structs

(* §1 structs (pass 1b): resolve each struct's field types now that every type
   name is registered, so a field may reference another struct. Records the
   ordered (name -> ty) fields and the names of fields lacking a default (the
   totality set for construction). *)
let register_struct_fields ctx (script : Ast.script) =
  List.iter
    (fun (sd : struct_decl) ->
      let seen = Hashtbl.create 8 in
      let fields =
        List.filter_map
          (fun (f : struct_field) ->
            if Hashtbl.mem seen f.srf_name then begin
              err ctx f.srf_pos "duplicate field '%s' in struct '%s'" f.srf_name sd.su_tyname;
              None
            end
            else begin
              Hashtbl.replace seen f.srf_name ();
              Some (f.srf_name, resolve_ty ctx f.srf_type)
            end)
          sd.su_fields
      in
      let required =
        List.filter_map
          (fun (f : struct_field) ->
            if f.srf_default = None && List.mem_assoc f.srf_name fields then Some f.srf_name
            else None)
          sd.su_fields
      in
      let reactive =
        List.filter_map
          (fun (f : struct_field) ->
            if f.srf_reactive && List.mem_assoc f.srf_name fields then Some f.srf_name else None)
          sd.su_fields
      in
      Hashtbl.replace ctx.structs sd.su_tyname
        { si_fields = fields; si_required = required; si_reactive = reactive })
    script.structs

(* §4.4 the diagnostic when a custom mob/item type is used as a reactive
   subject: it already owns its behavior in its own declaration block. *)
let reactive_custom_error ctx pos ~field ~cty ~base =
  err ctx pos
    "'%s' is a custom %s — it owns its behavior in its `%s %s` block and can't also drive the \
     reactive struct field '%s'. Put the logic in %s's handlers, or use a plain %s."
    cty
    (match base with RItem -> "item" | _ -> "mob")
    (match base with RItem -> "item" | _ -> "mob")
    cty field cty
    (match base with RItem -> "Item" | _ -> "Mob")

(* §4 validate the @EventReceiver modifier on a struct field: the field type must
   carry a receiver vocabulary (a base subject: Player/Entity/Mob/Item/Block).
   A scalar/struct type has no vocabulary (error); a nominal custom type is
   rejected by the §4.4 constraint (a custom type owns its own behavior). Returns
   the field's receiver kind when the field is a valid reactive subject. *)
let check_reactive_field_ty ctx pos ~field fty : Registry.receiver_kind option =
  match fty with
  | TCustomMob n -> reactive_custom_error ctx pos ~field ~cty:n ~base:RMob; None
  | TCustomItem n -> reactive_custom_error ctx pos ~field ~cty:n ~base:RItem; None
  | _ -> (
    match Registry.receiver_kind_of_ty fty with
    | Some rk -> Some rk
    | None ->
      err ctx pos
        "field '%s' is marked '@EventReceiver' but its type %s has no event vocabulary; only a base \
         subject (Player, Entity, Mob, Item, Block) can be a reactive receiver"
        field (ty_to_string fty);
      None)

(* §1 structs: check the declaration itself — each field default (if any) is
   present (unless the field is optional) and type-compatible with the field's
   declared type. Field types are resolved leniently (an unknown Capitalized
   name degrades to Any, like the nominal-type surface elsewhere).

   §4 additionally validates the reactive surface: each @EventReceiver field is a
   valid subject (§4.4), a struct carrying any @EventReceiver field must be
   serializable (reactive ⇒ persistent-capable), and each reactive block's
   handlers are typechecked in the struct's full bare-name context. *)
let check_struct_decl ctx (sd : struct_decl) =
  let bctx =
    { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false;
      in_schedule = false; override = None }
  in
  (* the field's receiver kind, keyed by field name, for the reactive blocks *)
  let subject_kinds = Hashtbl.create 8 in
  List.iter
    (fun (f : struct_field) ->
      let fty = resolve_ty ctx f.srf_type in
      if f.srf_reactive then (
        match check_reactive_field_ty ctx f.srf_pos ~field:f.srf_name fty with
        | Some rk -> Hashtbl.replace subject_kinds f.srf_name rk
        | None -> ());
      match f.srf_default with
      | None -> ()
      | Some e ->
        let dt = type_of ctx bctx empty_env e in
        (match fty with
        | TOptional _ -> ()
        | _ ->
          require_present ctx empty_env e dt
            ~use:(Printf.sprintf "the default value of field '%s'" f.srf_name));
        if not (param_compat fty dt) then
          err ctx e.epos "the default value of field '%s' must be %s (got %s)" f.srf_name
            (ty_to_string fty) (ty_to_string dt))
    sd.su_fields;
  (* §4.2/§4 reactive ⇒ serializable: a struct with any @EventReceiver field must
     be persistable (its liveness is persistence-rooted). Name the offending
     field, reusing the persistence serializability predicate. *)
  if List.exists (fun (f : struct_field) -> f.srf_reactive) sd.su_fields
     && not (reactive_serializable_ty ctx ~seen:[] (TStruct sd.su_tyname))
  then (
    match first_reactive_nonserializable_field ctx sd.su_tyname with
    | Some (fn, ft) ->
      err ctx sd.su_pos
        "reactive struct '%s' must be serializable (a reactive instance's liveness is \
         persistence-rooted): field '%s' has non-serializable type %s"
        sd.su_tyname fn (ty_to_string ft)
    | None ->
      err ctx sd.su_pos
        "reactive struct '%s' must be serializable (a reactive instance's liveness is \
         persistence-rooted)"
        sd.su_tyname);
  (* §4 typecheck each reactive block's handlers. The handler set is the FIELD
     TYPE's receiver vocabulary; the handlers are param-less with the struct's
     fields (including the subject field) and the event's vars bound as bare
     names — no `this`, reusing the inline-handler binding machinery. *)
  let field_tys = struct_fields ctx sd.su_tyname in
  List.iter
    (fun (r : struct_reactive) ->
      match List.assoc_opt r.sr_field field_tys with
      | None ->
        err ctx r.sr_field_pos
          "reactive block refers to unknown field '%s' in struct '%s'%s" r.sr_field sd.su_tyname
          (suggestion r.sr_field (List.map fst field_tys))
      | Some _ when not (List.mem r.sr_field (struct_reactive_fields ctx sd.su_tyname)) ->
        err ctx r.sr_field_pos
          "field '%s' has a reactive handler block but is not marked '@EventReceiver'; add the \
           '@EventReceiver' modifier to make it an event subject"
          r.sr_field
      | Some _ -> (
        match Hashtbl.find_opt subject_kinds r.sr_field with
        | None -> () (* the field-level check already reported the bad subject *)
        | Some rk ->
          let bctx_for (sg : Registry.handler_sig) =
            let event =
              Some
                { e_name = sg.h_event; e_cancellable = sg.h_cancellable; e_props = [];
                  e_aliases = [] }
            in
            { color = Sync; event; args = None; ret_sink = None; packet = false; api = false;
              in_schedule = false; override = None }
          in
          List.iter
            (fun (h : inline_handler) ->
              match Registry.find_receiver_method rk h.ih_event with
              | None ->
                err ctx h.ih_pos
                  "unknown %s handler '%s' on reactive field '%s'; valid handlers: %s%s"
                  (Registry.receiver_name rk) h.ih_event r.sr_field
                  (String.concat ", " (Registry.receiver_method_names rk))
                  (suggestion h.ih_event (Registry.receiver_method_names rk))
              | Some sg ->
                (* bind the struct's fields (subject included) as bare vars, then
                   the event's canonical args (an arg sharing a field name wins) *)
                let env =
                  List.fold_left (fun env (fn, fty) -> bind env fn fty) empty_env field_tys
                in
                let env =
                  List.fold_left (fun env (cn, pty) -> bind env cn pty) env sg.h_params
                in
                ignore (check_stmts ctx (bctx_for sg) env h.ih_body))
            r.sr_handlers))
    sd.su_reactive;
  (* §5 schema-migration validation + typecheck (v1.7.0 Batch B). The current
     struct fields are registered by now (register_struct_fields ran in pass 1b),
     so each field is bound as an assignable bare var and `raw` (the prior stored
     fields) is exposed as a map<String, Any> inside every migrate body. *)
  if sd.su_schema < 1 then
    err ctx sd.su_pos "struct '%s' schema version must be >= 1 (got %d)" sd.su_tyname sd.su_schema;
  (* schema/migrate only make sense on a persistent-capable (serializable) struct:
     migration exists to protect on-disk data. *)
  if
    (sd.su_schema <> 1 || sd.su_migrations <> [])
    && not (serializable_ty ctx ~seen:[] (TStruct sd.su_tyname))
  then (
    match first_nonserializable_field ctx sd.su_tyname with
    | Some (fn, ft) ->
      err ctx sd.su_pos
        "struct '%s' declares a schema/migration but is not persistent-capable: field '%s' has \
         non-serializable type %s"
        sd.su_tyname fn (ty_to_string ft)
    | None ->
      err ctx sd.su_pos
        "struct '%s' declares a schema/migration but is not persistent-capable" sd.su_tyname);
  (* validate migrate targets: each is in 2..schema, with no duplicate target *)
  let seen_targets = Hashtbl.create 8 in
  List.iter
    (fun (m : struct_migration) ->
      if m.sm_version < 2 then
        err ctx m.sm_pos
          "'migrate to %d' is invalid — a migrate target must be >= 2 (version 1 is the initial \
           schema, nothing migrates to it)"
          m.sm_version
      else if m.sm_version > sd.su_schema then
        err ctx m.sm_pos
          "struct '%s' has a 'migrate to %d' block but its schema is %d — the 'schema:' version \
           must be >= every migrate target"
          sd.su_tyname m.sm_version sd.su_schema;
      if Hashtbl.mem seen_targets m.sm_version then
        err ctx m.sm_pos "duplicate 'migrate to %d' block in struct '%s'" m.sm_version sd.su_tyname
      else Hashtbl.replace seen_targets m.sm_version ())
    sd.su_migrations;
  (* typecheck each migrate body: `raw` + the current fields are in scope; every
     assignment target must name a current field, and the assigned value must be
     compatible with that field's declared type. *)
  let raw_ty = TMap (TString, TAny) in
  List.iter
    (fun (m : struct_migration) ->
      let menv = List.fold_left (fun env (fn, fty) -> bind env fn fty) empty_env field_tys in
      let menv = bind menv "raw" raw_ty in
      ignore (check_stmts ctx bctx menv m.sm_body);
      (* assignment discipline: a migrate block ASSIGNS the current struct's
         fields; assigning anything else (a would-be temp / an unknown field) is
         a compile error, and the value must fit the field's type. *)
      let rec walk (s : stmt) =
        match s.s with
        | SAssign (x, v) -> (
          match List.assoc_opt x field_tys with
          | None ->
            err ctx s.spos "migrate block assigns '%s', which is not a field of struct '%s'%s" x
              sd.su_tyname
              (suggestion x (List.map fst field_tys))
          | Some fty ->
            let vt = type_of ctx bctx menv v in
            if not (param_compat fty vt) then
              err ctx v.epos "migrate assignment to field '%s' must be %s (got %s)" x
                (ty_to_string fty) (ty_to_string vt))
        | SBlock ss | SAsyncBlock ss -> List.iter walk ss
        | SIf (_, a, b) ->
          walk a;
          (match b with Some s -> walk s | None -> ())
        | SLoop (_, _, body) | SWhile (_, body) -> walk body
        | SForeach { fe_body; _ } -> walk fe_body
        | SForeachMap { fm_body; _ } -> walk fm_body
        | _ -> ()
      in
      List.iter walk m.sm_body)
    sd.su_migrations

let register_items ctx items =
  List.iter
    (fun (it : item_decl) ->
      if not (valid_item_id it.it_id) then
        err ctx it.it_pos
          "item id \"%s\" must use only lowercase [a-z0-9_.-] characters (it becomes part of \
           a namespaced key)"
          it.it_id;
      if Hashtbl.mem ctx.item_ids it.it_id then
        err ctx it.it_pos "duplicate item \"%s\"" it.it_id
      else Hashtbl.add ctx.item_ids it.it_id ())
    items

let register_mobs ctx mobs =
  List.iter
    (fun (mb : mob_decl) ->
      if Hashtbl.mem ctx.mob_ids mb.mb_id then err ctx mb.mb_pos "duplicate mob \"%s\"" mb.mb_id
      else Hashtbl.add ctx.mob_ids mb.mb_id ())
    mobs

let check_binding_shadows ctx pos what bindings =
  List.iter
    (fun b ->
      if Hashtbl.mem ctx.persists b then
        err ctx pos "persistent '%s' shadows the built-in '%s' binding of %s — rename the \
                     persistent"
          b b what)
    bindings

(* first-class inline handlers on item/mob/hologram/npc declarations
   (W-inline-handlers). Each handler's event name is validated against the
   kind's fixed handler table; the user binder names bind positionally to the
   fixed parameter types, `this` binds to the kind's instance type, and the
   body is sync-colored (no event binding, so async ops surface the sync
   error). *)
let check_inline_handlers ctx kind (handlers : inline_handler list) =
  let this_ty = decl_this_ty kind in
  let self_noun = Registry.decl_noun kind in
  (* a cancellable inline handler exposes a synthetic cancellable event so the
     body's `cancel event` typechecks (the runtime binds the real Minestom
     CancellableEvent as `event`); non-cancellable handlers keep event = None so
     `cancel event` still errors. *)
  let base_rk = Registry.base_receiver_of_kind kind in
  let bctx_for (sg : Registry.handler_sig) =
    (* expose the handler as an event context so `cancel event` typechecks; a
       non-cancellable handler carries e_cancellable = false, which makes
       `cancel event` report "not cancellable" rather than "not in a handler" *)
    let event =
      Some { e_name = sg.h_event; e_cancellable = sg.h_cancellable; e_props = []; e_aliases = [] }
    in
    (* this handler OVERRIDES the same-named base receiver method (most-specific
       wins); expose the base signature so the body may call default()/super *)
    let override = Registry.find_receiver_method base_rk sg.h_event in
    { color = Sync; event; args = None; ret_sink = None; packet = false; api = false;
      in_schedule = false; override }
  in
  List.iter
    (fun (h : inline_handler) ->
      match find_handler kind h.ih_event with
      | None ->
        err ctx h.ih_pos "unknown %s handler '%s'; valid handlers: %s%s" (decl_kind_name kind)
          h.ih_event
          (String.concat ", " (handler_names kind))
          (suggestion h.ih_event (handler_names kind))
      | Some sg ->
        let binder_names = self_noun :: List.map fst sg.h_params in
        check_binding_shadows ctx h.ih_pos
          (Printf.sprintf "the '%s' handler" h.ih_event)
          binder_names;
        (* bind the receiver instance under its noun, then the event's canonical
           args as bare variables (an arg sharing the self noun wins) *)
        let env = bind empty_env self_noun this_ty in
        let env = List.fold_left (fun env (cn, pty) -> bind env cn pty) env sg.h_params in
        ignore (check_stmts ctx (bctx_for sg) env h.ih_body))
    handlers

(* OOP receiver blocks (`Player { on_join() {} }`, ...). Each method name is
   validated against the receiver's fixed table (registry.ml); the user binder
   names bind positionally to the fixed parameter types, `this` binds to the
   receiver instance type, and the body is sync-colored. These are BASE methods
   (they override nothing), so override = None — `default()`/`super` are only
   available inside lowercase custom-declaration overrides. *)
let check_receiver ctx (r : receiver_decl) =
  match Registry.receiver_kind_of_name r.rc_type with
  | None ->
    err ctx r.rc_type_pos "unknown receiver type '%s'; valid receivers: %s%s" r.rc_type
      (String.concat ", " Registry.receiver_type_names)
      (suggestion r.rc_type Registry.receiver_type_names)
  | Some rk ->
    let this_ty = Registry.receiver_this_ty rk in
    let self_noun = Registry.receiver_noun rk in
    let bctx_for (sg : Registry.handler_sig) =
      let event =
        Some { e_name = sg.h_event; e_cancellable = sg.h_cancellable; e_props = []; e_aliases = [] }
      in
      { color = Sync; event; args = None; ret_sink = None; packet = false; api = false;
        in_schedule = false; override = None }
    in
    List.iter
      (fun (h : inline_handler) ->
        match Registry.find_receiver_method rk h.ih_event with
        | None ->
          err ctx h.ih_pos "unknown %s method '%s'; valid methods: %s%s" r.rc_type h.ih_event
            (String.concat ", " (Registry.receiver_method_names rk))
            (suggestion h.ih_event (Registry.receiver_method_names rk))
        | Some sg ->
          let binder_names = self_noun :: List.map fst sg.h_params in
          check_binding_shadows ctx h.ih_pos
            (Printf.sprintf "the '%s' method" h.ih_event)
            binder_names;
          (* bind the receiver instance under its noun, then the event's
             canonical args as bare variables (an arg sharing the self noun
             wins) *)
          let env = bind empty_env self_noun this_ty in
          let env = List.fold_left (fun env (cn, pty) -> bind env cn pty) env sg.h_params in
          ignore (check_stmts ctx (bctx_for sg) env h.ih_body))
      r.rc_methods

let check_receivers ctx (rs : receiver_decl list) = List.iter (check_receiver ctx) rs

let check_item_decl ctx it =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  (match (it.it_material, it.it_skull) with
  | Some _, Some _ ->
    err ctx it.it_pos "item \"%s\" cannot have both 'material' and 'skull'" it.it_id
  | None, None -> err ctx it.it_pos "item \"%s\" requires either 'material' or 'skull'" it.it_id
  | _ -> ());
  (match it.it_rarity with
  | Some (r, pos) when List.mem r removed_rarities ->
    (* pre-phase-9 Hypixel-ladder value: point at the vanilla set *)
    err ctx pos
      "rarity '%s' is not a SwoftLang rarity; only the four vanilla rarities are supported: %s \
       (custom tiers are userland data — model them with tags{} + lore)%s"
      r (String.concat ", " rarities) (suggestion r rarities)
  | Some (r, pos) when not (List.mem r rarities) ->
    err ctx pos "unknown rarity '%s'; valid rarities: %s%s" r (String.concat ", " rarities)
      (suggestion r rarities)
  | _ -> ());
  let string_field use = function
    | Some e ->
      let t = type_of ctx bctx empty_env e in
      require_present ctx empty_env e t ~use;
      (match t with
      | TString | TAny -> ()
      | _ -> err ctx e.epos "%s must be a String (got %s)" use (ty_to_string t))
    | None -> ()
  in
  string_field "the item name" it.it_name;
  (match it.it_glint with
  | Some e ->
    let t = type_of ctx bctx empty_env e in
    require_present ctx empty_env e t ~use:"the item glint";
    if not (boolish t) then
      err ctx e.epos "item glint must be a Boolean (got %s)" (ty_to_string t)
  | None -> ());
  (* amount: default stack size on give; a declaration scalar (literal on the
     Java side, like mob health) *)
  (match it.it_amount with
  | Some e ->
    let t = type_of ctx bctx empty_env e in
    require_present ctx empty_env e t ~use:"the item amount";
    if not (num_ok t) then
      err ctx e.epos "item amount must be a number (got %s)" (ty_to_string t)
    else if fold_number e = None then
      err ctx e.epos
        "item amount must be a constant number (only literal arithmetic is allowed in \
         declarations)"
  | None -> ());
  (* lore is rendered at registry build, but the runtime binds the item's own
     data into the lore environment (ItemLoreBuilder.LoreCollector.initialVars):
     'item_id' is this item's id and 'tags' is the (nested) tag tree, so lore
     lines may interpolate ${item_id} / ${tags.x} / ${tags.meta.tier}. tags is
     freeform NBT, so it types as TAny (property access on TAny stays TAny). *)
  let lore_env = bind (bind empty_env "item_id" TString) "tags" TAny in
  (match it.it_lore with
  | Some ss -> ignore (check_stmts ctx bctx lore_env ss)
  | None -> ());
  let numeric_entry what valid (k, pos, v) =
    if not (List.mem k valid) then
      err ctx pos "unknown %s '%s'; valid %ss: %s%s" what k what (String.concat ", " valid)
        (suggestion k valid);
    let t = type_of ctx bctx empty_env v in
    require_present ctx empty_env v t
      ~use:(Printf.sprintf "the value of %s '%s'" what k);
    if not (num_ok t) then
      err ctx v.epos "%s '%s' must be a number (got %s)" what k (ty_to_string t)
    else if fold_number v = None then
      (* declaration scalars must load as literals on the Java side *)
      err ctx v.epos "%s '%s' must be a constant number (only literal arithmetic is allowed \
                      in declarations)"
        what k
  in
  List.iter (numeric_entry "attribute" item_attribute_names) it.it_attributes;
  (* nested NBT (phase 9 §2): scalars, lists, and compounds. tag data is
     constant declaration data — validate the leaves are scalars and recurse
     through lists/compounds. *)
  let rec check_tag_value k v =
    match v.e with
    | EMap entries -> List.iter (fun (_, sub) -> check_tag_value k sub) entries
    | EList items -> List.iter (check_tag_value k) items
    | _ ->
      let t = type_of ctx bctx empty_env v in
      require_present ctx empty_env v t ~use:(Printf.sprintf "the value of tag '%s'" k);
      (match t with
      | TString | TInteger | TDouble | TBoolean | TAny -> ()
      | _ ->
        err ctx v.epos
          "item tag '%s' must be a scalar (String, Integer, Double, or Boolean), a list, or a \
           nested compound, got %s"
          k (ty_to_string t))
  in
  List.iter (fun (k, v) -> check_tag_value k v) it.it_tags;
  (* on_click(<filter>) sugar (phase 9): a filtered use-item handler for this
     item. It binds player + item and behaves like a cancellable PlayerUseItem
     handler, so 'cancel event' is legal inside it. *)
  (match find_event "PlayerUseItem" with
  | None -> ()
  | Some use_def ->
    List.iter
      (fun (ch : click_handler) ->
        (* the parser has already restricted the filter to left|right|any *)
        check_binding_shadows ctx it.it_pos "an on_click handler" [ "player"; "item" ];
        let cbctx =
          { color = Sync; event = Some use_def; args = None; ret_sink = None; packet = false;
            api = false; in_schedule = false; override = None }
        in
        let env = bind (bind empty_env "player" TPlayer) "item" TItem in
        ignore (check_stmts ctx cbctx env ch.ch_body))
      it.it_on_click);
  check_inline_handlers ctx KItem it.it_handlers

let check_mob_decl ctx mb =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  (match mb.mb_type with
  | Some (t, pos) ->
    if not (entity_type_exists t) then
      err ctx pos "unknown entity type '%s'%s" t
        (suggestion (normalize_entity_type t) entity_types)
  | None -> ());
  (* the mob is in scope in its own declaration: the name template re-renders
     live against the mob (design 5B), handlers bind it explicitly *)
  let menv = bind empty_env "mob" TMob in
  (match mb.mb_name with
  | Some e ->
    let t = type_of ctx bctx menv e in
    require_present ctx menv e t ~use:"the mob name";
    (match t with
    | TString | TAny -> ()
    | _ -> err ctx e.epos "mob name must be a String (got %s)" (ty_to_string t))
  | None -> ());
  let numeric_field use = function
    | Some e ->
      let t = type_of ctx bctx menv e in
      require_present ctx menv e t ~use;
      if not (num_ok t) then err ctx e.epos "%s must be a number (got %s)" use (ty_to_string t)
      else if fold_number e = None then
        (* the Java loader reads these through scalarNumber, literals only *)
        err ctx e.epos "%s must be a constant number (only literal arithmetic is allowed in \
                        declarations)"
          use
    | None -> ()
  in
  numeric_field "mob health" mb.mb_health;
  numeric_field "mob damage" mb.mb_damage;
  numeric_field "mob speed" mb.mb_speed;
  (match mb.mb_ai with
  | Some (a, pos) when not (List.mem a mob_ais) ->
    err ctx pos "unknown ai mode '%s'; valid modes: %s%s" a (String.concat ", " mob_ais)
      (suggestion a mob_ais)
  | _ -> ());
  List.iter
    (fun dr ->
      if not (Hashtbl.mem ctx.item_ids dr.dr_id) && not (vanilla_material_like dr.dr_id) then
        err ctx dr.dr_pos
          "unknown item '%s' in drops; declare it with 'item \"%s\" { }' or use an ALL_CAPS \
           vanilla material name%s"
          dr.dr_id dr.dr_id
          (suggestion dr.dr_id (known_item_ids ctx));
      let ct = type_of ctx bctx menv dr.dr_chance in
      require_present ctx menv dr.dr_chance ct ~use:"the drop chance";
      if not (num_ok ct) then
        err ctx dr.dr_chance.epos "drop chance must be a number (got %s)" (ty_to_string ct)
      else (
        (* fold first so '5.0 / 100' style arithmetic is range-checked too;
           non-constant expressions cannot load on the Java side *)
        match fold_number dr.dr_chance with
        | Some f ->
          if f <= 0.0 || f > 1.0 then
            err ctx dr.dr_chance.epos "drop chance must be in (0, 1] (got %g)" f
        | None ->
          err ctx dr.dr_chance.epos
            "drop chance must be a constant number (only literal arithmetic is allowed in \
             declarations)");
      match dr.dr_amount with
      | Some a ->
        let at = type_of ctx bctx menv a in
        require_present ctx menv a at ~use:"the drop amount";
        if not (num_ok at) then
          err ctx a.epos "drop amount must be a number (got %s)" (ty_to_string at)
        else if fold_number a = None then
          err ctx a.epos "drop amount must be a constant number (only literal arithmetic is \
                          allowed in declarations)"
      | None -> ())
    mb.mb_drops;
  (* typed tag block (W-viewers §2): declare mob.tags.<name> with a type (an
     empty, indexable store) or an item-style value init (type inferred). The
     mapping is published on ctx while checking this mob's handlers so
     mob.tags.<declared> resolves to its declared type. *)
  let seen_tags = Hashtbl.create 8 in
  let tag_tys =
    List.map
      (fun (mt : mob_tag) ->
        if Hashtbl.mem seen_tags mt.mt_name then
          err ctx mt.mt_pos "duplicate mob tag '%s'" mt.mt_name;
        Hashtbl.replace seen_tags mt.mt_name ();
        let ty =
          match mt.mt_spec with
          | MTType dt -> ty_of_dt dt
          | MTValue e ->
            let t = type_of ctx bctx menv e in
            require_present ctx menv e t
              ~use:(Printf.sprintf "the '%s' tag value" mt.mt_name);
            t
        in
        (mt.mt_name, ty))
      mb.mb_tags
  in
  ctx.cur_mob_tags <- tag_tys;
  (* the dedicated mob handlers (on_spawn/on_death/on_attack/on_hit) OVERRIDE the
     same-named base Mob receiver method (most-specific wins), so their bodies may
     call default()/super to chain into it — exactly like the generic inline
     handlers below. Expose the base signature via bctx.override so those chain
     calls typecheck; the runtime binds the matching $override context. *)
  let base_rk = Registry.base_receiver_of_kind KMob in
  let override_for what = { bctx with override = Registry.find_receiver_method base_rk what } in
  let handler what bindings body =
    match body with
    | None -> ()
    | Some ss ->
      check_binding_shadows ctx mb.mb_pos what (List.map fst bindings);
      let env = List.fold_left (fun env (name, ty) -> bind env name ty) empty_env bindings in
      ignore (check_stmts ctx (override_for what) env ss)
  in
  handler "on_spawn" [ ("mob", TMob) ] mb.mb_on_spawn;
  handler "on_death" [ ("mob", TMob); ("killer", TOptional TPlayer) ] mb.mb_on_death;
  handler "on_attack" [ ("mob", TMob); ("victim", TPlayer) ] mb.mb_on_attack;
  (* on_hit: sync-colored, binds the bare 'mob' and 'attacker'
     (optional<Player>) variables in scope *)
  handler "on_hit" [ ("mob", TMob); ("attacker", TOptional TPlayer) ] mb.mb_on_hit;
  check_inline_handlers ctx KMob mb.mb_handlers;
  ctx.cur_mob_tags <- []

(* --- first-class holograms + npcs (GROUP C/D) --- *)

let check_holograms ctx (hs : hologram list) =
  let bctx =
    { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false;
      in_schedule = false; override = None }
  in
  let seen = Hashtbl.create 8 in
  List.iter
    (fun (h : hologram) ->
      if Hashtbl.mem seen h.h_name then err ctx h.h_pos "duplicate hologram \"%s\"" h.h_name
      else Hashtbl.add seen h.h_name ();
      (* per-viewer capable: 'player' is bound in the line environment exactly
         like scoreboards (the emitter decides per-viewer render when a line
         references it) *)
      let env = bind empty_env "player" TPlayer in
      let lt = type_of ctx bctx env h.h_location in
      require_present ctx env h.h_location lt ~use:"the hologram location";
      (match lt with
      | TLocation | TAny -> ()
      | _ -> err ctx h.h_location.epos "hologram location must be a Location (got %s)" (ty_to_string lt));
      if not (List.mem h.h_billboard display_billboards) then
        err ctx h.h_billboard_pos "unknown billboard mode '%s'; valid modes: %s%s" h.h_billboard
          (String.concat ", " display_billboards)
          (suggestion h.h_billboard display_billboards);
      (match h.h_scale with
      | Some e ->
        let t = type_of ctx bctx env e in
        require_present ctx env e t ~use:"the hologram scale";
        if not (num_ok t) then
          err ctx e.epos "hologram scale must be a number (got %s)" (ty_to_string t)
      | None -> ());
      (match h.h_update with
      | UTicks n when n <= 0 -> err ctx h.h_pos "update cadence must be positive"
      | _ -> ());
      ignore (check_stmts ctx bctx env h.h_lines);
      check_inline_handlers ctx KHologram h.h_handlers)
    hs

let check_npcs ctx (ns : npc list) =
  let bctx =
    { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false;
      in_schedule = false; override = None }
  in
  let seen = Hashtbl.create 8 in
  List.iter
    (fun (n : npc) ->
      if Hashtbl.mem seen n.n_name then err ctx n.n_pos "duplicate npc \"%s\"" n.n_name
      else Hashtbl.add seen n.n_name ();
      (* the overhead name is per-viewer capable: 'player' is bound while it is
         rendered, so ${player.name}-style names resolve per viewer *)
      let env = bind empty_env "player" TPlayer in
      let lt = type_of ctx bctx env n.n_location in
      require_present ctx env n.n_location lt ~use:"the npc location";
      (match lt with
      | TLocation | TAny -> ()
      | _ -> err ctx n.n_location.epos "npc location must be a Location (got %s)" (ty_to_string lt));
      (match n.n_display_name with
      | Some e ->
        let t = type_of ctx bctx env e in
        require_present ctx env e t ~use:"the npc name";
        (match t with
        | TString | TAny -> ()
        | _ -> err ctx e.epos "npc name must be a String (got %s)" (ty_to_string t))
      | None -> ());
      (match n.n_skin with Some sk -> check_npc_skin ctx bctx env sk | None -> ());
      (* on_click(player) / on_left_click(player): sync-colored, binds the named
         player; the binder must not shadow a persistent *)
      let handler what = function
        | None -> ()
        | Some ss ->
          check_binding_shadows ctx n.n_pos what [ "npc"; "player" ];
          let henv = bind (bind empty_env "npc" TEntity) "player" TPlayer in
          ignore (check_stmts ctx bctx henv ss)
      in
      handler "an on_click handler" n.n_on_click;
      handler "an on_left_click handler" n.n_on_left_click;
      check_inline_handlers ctx KNpc n.n_handlers)
    ns

(* --- phase-8 fishing loot tables --- *)

let check_fishing_loots ctx (fls : fishing_loot list) =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
  let seen = Hashtbl.create 8 in
  List.iter
    (fun (fl : fishing_loot) ->
      if Hashtbl.mem seen fl.fl_name then
        err ctx fl.fl_pos "duplicate fishing_loot \"%s\"" fl.fl_name
      else Hashtbl.add seen fl.fl_name ();
      (match fl.fl_medium with
      | Some (m, pos) when not (List.mem m fishing_mediums) ->
        err ctx pos "unknown fishing medium '%s'; valid mediums: %s%s" m
          (String.concat ", " fishing_mediums)
          (suggestion m fishing_mediums)
      | _ -> ());
      List.iter
        (fun (c : fishing_catch) ->
          (if c.fc_mob then begin
             if not (Hashtbl.mem ctx.mob_ids c.fc_id) then
               err ctx c.fc_pos
                 "unknown mob '%s' in fishing_loot \"%s\"; declare it with 'mob \"%s\" { }'%s"
                 c.fc_id fl.fl_name c.fc_id
                 (suggestion c.fc_id (known_mob_ids ctx))
           end
           else if
             (not (Hashtbl.mem ctx.item_ids c.fc_id)) && not (vanilla_material_like c.fc_id)
           then
             err ctx c.fc_pos
               "unknown item '%s' in fishing_loot \"%s\"; declare it with 'item \"%s\" { }' or \
                use an ALL_CAPS vanilla material name%s"
               c.fc_id fl.fl_name c.fc_id
               (suggestion c.fc_id (known_item_ids ctx)));
          let wt = type_of ctx bctx empty_env c.fc_weight in
          require_present ctx empty_env c.fc_weight wt ~use:"the catch weight";
          if not (num_ok wt) then
            err ctx c.fc_weight.epos "catch weight must be a number (got %s)" (ty_to_string wt)
          else
            (* fold first so '80 / 2' style arithmetic is range-checked too;
               the Java loader reads weights as literal scalars *)
            match fold_number c.fc_weight with
            | Some f ->
              if f <= 0.0 then
                err ctx c.fc_weight.epos "catch weight must be positive (got %g)" f
            | None ->
              err ctx c.fc_weight.epos
                "catch weight must be a constant number (only literal arithmetic is allowed in \
                 declarations)")
        fl.fl_catches)
    fls

let check_packet_listener ctx pk =
  match pk.pk_execute with
  | None -> ()
  | Some ex ->
    (* design 5D: Packet handlers are a restricted sync color — they run
       on the packet path, so wait/spawn are banned and async{} re-opens them *)
    if ex.ex_async then
      err ctx pk.pk_pos
        "Packet handlers always run sync; use an 'async { }' block inside";
    check_binding_shadows ctx pk.pk_pos "a Packet handler" [ "player"; "packet" ];
    (* validate the packet class name against the catalog (accepts either the
       bare simple name or the fully-qualified name); an unknown class errors
       with a nearest-match suggestion. On success, bind `packet`'s field set so
       packet.<field> typechecks to the real field type inside the body. *)
    let fields =
      match Registry.resolve_packet_class pk.pk_name with
      | Some fq when Registry.packet_direction fq = Some "server" ->
        (* the class exists but is outbound: the runtime PacketSender.resolveClient
           only accepts inbound client packets, so listening to it can never fire *)
        err ctx pk.pk_pos
          "packet class \"%s\" is an outbound server packet; a Packet block can only listen to inbound client packets%s"
          pk.pk_name
          (suggestion pk.pk_name (Registry.client_packet_class_names ()));
        []
      | Some fq ->
        List.map (fun (p : Registry.prop) -> (p.p_name, p.p_ty)) (Registry.packet_fields fq)
      | None ->
        err ctx pk.pk_pos "unknown packet class \"%s\"%s" pk.pk_name
          (suggestion pk.pk_name (Registry.client_packet_class_names ()));
        []
    in
    ctx.cur_packet_fields <- Some (pk.pk_name, fields);
    let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = true; api = false; in_schedule = false; override = None } in
    let env = bind (bind empty_env "player" TPlayer) "packet" TAny in
    ignore (check_stmts ctx bctx env ex.ex_stmts);
    ctx.cur_packet_fields <- None

(* --- phase-6 api / scheduler declarations --- *)

let check_api_decl ctx (a : api_decl) =
  if String.length a.api_path = 0 || a.api_path.[0] <> '/' then
    err ctx a.api_pos "api path \"%s\" must start with '/'" a.api_path;
  (match a.api_method with
  | Some (m, pos) ->
    if not (List.mem (String.uppercase_ascii m) api_methods) then
      err ctx pos "unknown http method '%s'; valid methods: %s%s" m
        (String.concat ", " api_methods)
        (suggestion (String.uppercase_ascii m) api_methods)
  | None -> ());
  match a.api_execute with
  | None -> ()
  | Some ex ->
    (* design 6B: api handlers are async-colored by default — they run off
       the tick thread on virtual threads, so both 'execute' and 'execute
       async' check as async *)
    check_binding_shadows ctx a.api_pos "the api handler" [ "request" ];
    let bctx =
      { color = Async; event = None; args = None; ret_sink = None; packet = false; api = true; in_schedule = false; override = None }
    in
    let env = bind (base_env ctx) "request" TRequest in
    ignore (check_stmts ctx bctx env ex.ex_stmts)

let check_sched_decl ctx (sd : sched_decl) =
  if sd.sd_every <= 0 then err ctx sd.sd_pos "scheduler cadence must be positive";
  (* async-colored: the body runs on the AsyncRuntime, tick-aligned. 'stop'
     is legal and the 1-based 'run' counter is in scope (scheduler v2) *)
  let bctx =
    { color = Async; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = true; override = None }
  in
  ignore (check_stmts ctx bctx (bind (base_env ctx) "run" TInteger) sd.sd_body)

(* --- W-blocks: block_handler / placement_rule callbacks ---

   Each callback binds its user-chosen parameter names to the hook's fixed
   types, is sync-colored, and — when the hook has a required return type
   (on_interact -> Boolean, on_place/on_update -> Block) — must return a value
   of that type on every path. Hooks without a return type must not return a
   value. A written '-> Type' annotation is cross-checked against the fixed
   type. *)
let check_block_cb ctx kind (sg : Registry.block_cb_sig) (cb : block_cb) =
  begin
    check_binding_shadows ctx cb.cb_pos
      (Printf.sprintf "the '%s' callback" cb.cb_name)
      (List.map fst sg.bcb_params);
    (* a written '-> Type' must agree with the hook's fixed return type *)
    (match (cb.cb_ret, sg.bcb_ret) with
    | Some dt, Some expected ->
      let written = ty_of_dt dt in
      if not (param_compat expected written || param_compat written expected) then
        err ctx cb.cb_pos "%s callback '%s' returns %s, but '-> %s' was written" kind cb.cb_name
          (ty_to_string expected) (ty_to_string written)
    | Some dt, None ->
      err ctx cb.cb_pos "%s callback '%s' does not return a value, but '-> %s' was written" kind
        cb.cb_name (ty_to_string (ty_of_dt dt))
    | None, _ -> ());
    (* bind the hook's canonical arg names as bare variables in scope *)
    let env =
      List.fold_left (fun env (cn, pty) -> bind env cn pty) empty_env sg.bcb_params
    in
    let vals = ref [] in
    let bare = ref false in
    let bctx =
      { color = Sync; event = None; args = None; ret_sink = Some (vals, bare); packet = false;
        api = false; in_schedule = false; override = None }
    in
    let _, terminates = check_stmts ctx bctx env cb.cb_body in
    match sg.bcb_ret with
    | None ->
      if !vals <> [] || !bare then
        err ctx cb.cb_pos "%s callback '%s' must not return a value" kind cb.cb_name
    | Some expected ->
      List.iter
        (fun t ->
          if not (param_compat expected t) then
            err ctx cb.cb_pos "%s callback '%s' must return %s (got %s)" kind cb.cb_name
              (ty_to_string expected) (ty_to_string t))
        !vals;
      if !bare then
        err ctx cb.cb_pos "%s callback '%s' must return a %s, not a bare 'return'" kind cb.cb_name
          (ty_to_string expected)
      else if not terminates then
        err ctx cb.cb_pos "%s callback '%s' must return a %s on every path" kind cb.cb_name
          (ty_to_string expected)
  end

let check_block_callbacks ctx kind cbs callbacks =
  let seen = Hashtbl.create 8 in
  List.iter
    (fun (cb : block_cb) ->
      if Hashtbl.mem seen cb.cb_name then
        err ctx cb.cb_pos "duplicate %s callback '%s'" kind cb.cb_name
      else Hashtbl.replace seen cb.cb_name ();
      match find_block_cb cbs cb.cb_name with
      | None ->
        err ctx cb.cb_pos "unknown %s callback '%s'; valid callbacks: %s%s" kind cb.cb_name
          (String.concat ", " (block_cb_names cbs))
          (suggestion cb.cb_name (block_cb_names cbs))
      | Some sg -> check_block_cb ctx kind sg cb)
    callbacks

let check_block_handlers ctx (bhs : block_handler_decl list) =
  let seen = Hashtbl.create 8 in
  List.iter
    (fun (bh : block_handler_decl) ->
      let key = normalize_block_id bh.bh_id in
      if Hashtbl.mem seen key then err ctx bh.bh_pos "duplicate block_handler for \"%s\"" bh.bh_id
      else Hashtbl.replace seen key ();
      (* a minecraft-namespaced (or bare) id must name a real block; a custom
         namespace (myplugin:foo) is a user-defined handler key, accepted *)
      let is_minecraft =
        match String.index_opt key ':' with
        | Some i -> String.sub key 0 i = "minecraft"
        | None -> true
      in
      if is_minecraft && not (block_known bh.bh_id) then
        err ctx bh.bh_pos "unknown block \"%s\" in block_handler%s" bh.bh_id
          (suggestion (block_short bh.bh_id) (block_id_suggestions ()));
      check_block_callbacks ctx "block_handler" Registry.block_handler_cbs bh.bh_callbacks)
    bhs

let check_placement_rules ctx (prs : placement_rule_decl list) =
  let seen = Hashtbl.create 8 in
  List.iter
    (fun (pr : placement_rule_decl) ->
      let key = normalize_block_id pr.pr_id in
      if Hashtbl.mem seen key then err ctx pr.pr_pos "duplicate placement_rule for \"%s\"" pr.pr_id
      else Hashtbl.replace seen key ();
      check_block_id_string ctx pr.pr_pos pr.pr_id ~where:"placement_rule";
      check_block_callbacks ctx "placement_rule" Registry.placement_rule_cbs pr.pr_callbacks)
    prs

let check_servers ctx servers =
  (match servers with
  | [] | [ _ ] -> ()
  | _ :: rest ->
    List.iter
      (fun s ->
        err ctx s.sv_pos "duplicate 'server' block; only one server block is allowed per script")
      rest);
  List.iter
    (fun s ->
      (match s.sv_port with
      | Some p when p < 1 || p > 65535 ->
        err ctx s.sv_pos "server port must be between 1 and 65535 (got %d)" p
      | _ -> ());
      (match s.sv_http with
      | Some hc when hc.hc_port < 1 || hc.hc_port > 65535 ->
        err ctx s.sv_pos "http port must be between 1 and 65535 (got %d)" hc.hc_port
      | _ -> ());
      match s.sv_fishing with
      | Some fc ->
        if fc.fi_min_bite <= 0 then err ctx s.sv_pos "fishing min_bite must be positive";
        if fc.fi_max_bite < fc.fi_min_bite then
          err ctx s.sv_pos "fishing max_bite must be at least min_bite (got %d < %d ticks)"
            fc.fi_max_bite fc.fi_min_bite
      | None -> ())
    servers
