open Ast
open Registry
open Tc_env

let check_gamemode_literal ctx value =
  match value.e with
  | EString s when not (String.length s >= 2 && String.contains s '$') ->
    if not (List.mem (String.lowercase_ascii s) gamemodes) then
      err ctx value.epos "invalid gamemode '%s'; valid values: %s" s
        (String.concat ", " gamemodes)
  | _ -> ()

(* --- phase-5 literal validation (item/mob ids, nametag colors) --- *)

let contains_interp s =
  let n = String.length s in
  let rec go i = i + 1 < n && ((s.[i] = '$' && s.[i + 1] = '{') || go (i + 1)) in
  go 0

(* a string literal whose value is fully known at compile time *)
let literal_string e =
  match e.e with
  | EString s when not (contains_interp s) -> Some s
  | _ -> None

(* ALL_CAPS ids name vanilla materials in mob drops (design 5B: custom or
   vanilla ids); custom item ids are lowercase by convention *)
let vanilla_material_like s =
  String.length s > 0
  && (match s.[0] with 'A' .. 'Z' -> true | _ -> false)
  && String.for_all (function 'A' .. 'Z' | '0' .. '9' | '_' -> true | _ -> false) s

let known_item_ids ctx = Hashtbl.fold (fun k _ acc -> k :: acc) ctx.item_ids []
let known_mob_ids ctx = Hashtbl.fold (fun k _ acc -> k :: acc) ctx.mob_ids []

(* --- reference validation: a statement that names a declaration must
   resolve it against the compilation unit's registry (design 5B-style, the
   way give item "id"/spawn mob "id" already validate). --- *)

let table_keys tbl = Hashtbl.fold (fun k _ acc -> k :: acc) tbl []

(* show/hide/update scoreboard|tablist|bossbar "name", open/replace gui "name":
   the name is a raw string from the parser, so the position is the statement's
   own position. *)
let check_decl_name ctx pos kind tbl name =
  if not (Hashtbl.mem tbl name) then
    err ctx pos "unknown %s '%s'; declare it with '%s \"%s\" { }'%s" kind name kind name
      (suggestion name (table_keys tbl))

(* cancel schedule "name" / is_running("name"): the string form of the
   scheduler v2 API resolves a named schedule created by a top-level
   'every ... as "name"' or an inline 'schedule ... as "name"'. Only literal
   names are checked — a computed String name is resolved at runtime. *)
let check_schedule_name_literal ctx e ~where =
  match literal_string e with
  | Some s when not (Hashtbl.mem ctx.schedules s) ->
    err ctx e.epos
      "unknown schedule '%s' in %s; name one with 'every ... as \"%s\"' or \
       'schedule ... as \"%s\"'%s"
      s where s s
      (suggestion s (table_keys ctx.schedules))
  | _ -> ()

let check_item_id_literal ctx e ~allow_vanilla ~where =
  match literal_string e with
  | Some s when not (Hashtbl.mem ctx.item_ids s) ->
    if not (allow_vanilla && vanilla_material_like s) then
      err ctx e.epos "unknown item '%s' in %s; declare it with 'item \"%s\" { }'%s%s" s where s
        (if allow_vanilla then " or use an ALL_CAPS vanilla material name" else "")
        (suggestion s (known_item_ids ctx))
  | _ -> ()

let check_mob_id_literal ctx e ~where =
  match literal_string e with
  | Some s when not (Hashtbl.mem ctx.mob_ids s) ->
    err ctx e.epos "unknown mob '%s' in %s; declare it with 'mob \"%s\" { }'%s" s where s
      (suggestion s (known_mob_ids ctx))
  | _ -> ()

(* phase-7: literal vanilla EntityType names in 'spawn entity' /
   'launch projectile' / all_entities(...) validate against the pinned
   Minestom EntityType list *)
let check_entity_type_literal ctx e ~where =
  match literal_string e with
  | Some s when not (entity_type_exists s) ->
    err ctx e.epos "unknown entity type '%s' in %s%s" s where
      (suggestion (normalize_entity_type s) entity_types)
  | _ -> ()

let check_nametag_color_literal ctx value =
  match literal_string value with
  | Some s ->
    let lc = String.lowercase_ascii s in
    if not (List.mem lc nametag_colors) then
      err ctx value.epos "unknown nametag color '%s'; valid colors: %s%s" s
        (String.concat ", " nametag_colors)
        (suggestion lc nametag_colors)
  | None -> ()

(* phase 10: the entity 'pose' row is an EntityPose enum (snake_case); a literal
   write is validated against the pinned Minestom enum names *)
let check_pose_literal ctx value =
  match literal_string value with
  | Some s ->
    let lc = String.lowercase_ascii s in
    if not (List.mem lc entity_poses) then
      err ctx value.epos "unknown pose '%s'; valid poses: %s%s" s
        (String.concat ", " entity_poses)
        (suggestion lc entity_poses)
  | None -> ()

(* phase 10: the World 'weather' row is a clear|rain|thunder enum *)
let check_weather_literal ctx value =
  match literal_string value with
  | Some s ->
    let lc = String.lowercase_ascii s in
    if not (List.mem lc weather_states) then
      err ctx value.epos "unknown weather '%s'; valid weather: %s%s" s
        (String.concat ", " weather_states)
        (suggestion lc weather_states)
  | None -> ()

(* enum-valued display rows validate literal writes (design 6B): billboard,
   alignment, and glow_color (a NamedTextColor name) *)
let check_display_string_literal ctx name value =
  match literal_string value with
  | None -> ()
  | Some s -> (
    let lc = String.lowercase_ascii s in
    let check what valid =
      if not (List.mem lc valid) then
        err ctx value.epos "unknown %s '%s'; valid values: %s%s" what s
          (String.concat ", " valid) (suggestion lc valid)
    in
    match name with
    | "billboard" -> check "billboard mode" display_billboards
    | "alignment" -> check "text alignment" display_alignments
    | "glow_color" -> check "glow color" nametag_colors
    | _ -> ())

(* --- static line counting for sidebar / tablist caps --- *)

let literal_count e =
  match e.e with
  | ENumber { value; integer = true } -> ( match int_of_string_opt value with Some n -> n | None -> 1)
  | _ -> 1

let rec count_units kind stmts = List.fold_left (fun acc s -> acc + count_unit kind s) 0 stmts

and count_unit kind s =
  match s.s with
  | SLine _ | SBlank -> if kind = `Lines then 1 else 0
  | SEntry _ -> if kind = `Column then 1 else 0
  | SFill _ -> 0
  | SIf (_, t, e) ->
    max (count_unit kind t) (match e with Some e -> count_unit kind e | None -> 0)
  | SLoop (cnt, _, body) -> literal_count cnt * count_unit kind body
  | SForeach { fe_limit; fe_body; _ } ->
    let mult = match fe_limit with Some l -> literal_count l | None -> 1 in
    mult * count_unit kind fe_body
  | SBlock ss -> count_units kind ss
  | _ -> 0
