open Ast

let opt f = function
  | None -> `Null
  | Some x -> f x

let str s = `String s
let int_opt = function None -> `Null | Some i -> `Int i

let with_pos (pos : pos) fields =
  ("line", `Int pos.line) :: ("col", `Int pos.col) :: fields

let rec data_type = function
  | DSimple base -> `Assoc [ ("base", `String base) ]
  | DEither subs ->
    `Assoc [ ("base", `String "EITHER"); ("subtypes", `List (List.map data_type subs)) ]
  | DOptional sub ->
    `Assoc [ ("base", `String "OPTIONAL"); ("subtypes", `List [ data_type sub ]) ]
  | DList sub ->
    `Assoc [ ("base", `String "LIST"); ("subtypes", `List [ data_type sub ]) ]
  | DMap (DSimple "STRING", sub) ->
    (* String-keyed maps emit exactly as before (byte-identical sidecars) *)
    `Assoc [ ("base", `String "MAP"); ("subtypes", `List [ data_type sub ]) ]
  | DMap (key, sub) ->
    (* an Integer-keyed map additionally carries its key type (phase 11) *)
    `Assoc
      [
        ("base", `String "MAP");
        ("key_type", data_type key);
        ("subtypes", `List [ data_type sub ]);
      ]

let param p =
  `Assoc
    (with_pos p.p_pos [ ("name", `String p.p_name); ("type", opt data_type p.p_type) ])

(* shared between storage{} blocks and polar_storage_loader(...) exprs *)
let backend = function
  | BFiles path -> `Assoc [ ("kind", `String "files"); ("path", `String path) ]
  | BSqlite path -> `Assoc [ ("kind", `String "sqlite"); ("path", `String path) ]
  | BMysql { host; port; database; user; password } ->
    `Assoc
      [
        ("kind", `String "mysql");
        ("host", `String host);
        ("port", `Int port);
        ("database", `String database);
        ("user", `String user);
        ("password", `String password);
      ]
  | BMongodb uri -> `Assoc [ ("kind", `String "mongodb"); ("uri", `String uri) ]

let rec expr (e : Ast.expr) : Yojson.Safe.t =
  let node fields = `Assoc (with_pos e.epos fields) in
  match e.e with
  | EString value -> node [ ("kind", `String "string"); ("value", `String value) ]
  | ENumber { value; integer } ->
    let v =
      if integer then
        match int_of_string_opt value with
        | Some i -> `Int i
        | None -> `Float (float_of_string value)
      else `Float (float_of_string value)
    in
    node [ ("kind", `String "number"); ("value", v); ("integer", `Bool integer) ]
  | EBool b -> node [ ("kind", `String "boolean"); ("value", `Bool b) ]
  | ENone -> node [ ("kind", `String "none") ]
  | EVar name -> node [ ("kind", `String "var"); ("name", `String name) ]
  | EType name -> node [ ("kind", `String "type"); ("name", `String name) ]
  | EBinary (op, left, right) ->
    node
      [ ("kind", `String "binary"); ("op", `String op); ("left", expr left);
        ("right", expr right) ]
  | EUnary (op, operand) ->
    node [ ("kind", `String "unary"); ("op", `String op); ("operand", expr operand) ]
  | ECall (name, args) ->
    node
      [ ("kind", `String "call"); ("name", `String name); ("args", `List (List.map expr args)) ]
  | EMethod (recv, name, args) ->
    node
      [ ("kind", `String "method_call"); ("receiver", expr recv); ("name", `String name);
        ("args", `List (List.map expr args)) ]
  | EAllPlayers -> node [ ("kind", `String "all_players") ]
  | EList items -> node [ ("kind", `String "list"); ("items", `List (List.map expr items)) ]
  | EProp (target, name) ->
    node [ ("kind", `String "prop"); ("target", expr target); ("name", `String name) ]
  | EPersistGet (name, subject) ->
    node [ ("kind", `String "persist_get"); ("name", `String name); ("subject", opt expr subject) ]
  | ELambda { lam_async; lam_params; lam_body } ->
    node
      [ ("kind", `String "lambda"); ("async", `Bool lam_async);
        ("params", `List (List.map param lam_params));
        ("body", `List (List.map stmt lam_body)) ]
  | EMap entries ->
    node
      [ ("kind", `String "map");
        ("entries", `Assoc (List.map (fun (k, v) -> (k, expr v)) entries)) ]
  | EStructNew (name, fields) ->
    (* §1 struct construction: the type name plus the supplied fields, as an
       ordered {name: value} list so source order (and the runtime's field
       binding) is preserved *)
    node
      [ ("kind", `String "struct_new"); ("struct", `String name);
        ( "fields",
          `List
            (List.map
               (fun (k, v) -> `Assoc [ ("name", `String k); ("value", expr v) ])
               fields) ) ]
  | EMapLit entries ->
    (* map<K, V> literal: an ordered list of {key,value} entries so duplicate
       keys and insertion order survive to the LinkedHashMap runtime. A String
       key emits "key": "s" (byte-identical to phase 10); an Integer key emits
       "key": <int> (phase 11). *)
    let key_json = function
      | MKStr s -> `String s
      | MKInt n -> ( match int_of_string_opt n with Some i -> `Int i | None -> `String n)
    in
    node
      [ ("kind", `String "map_lit");
        ( "entries",
          `List
            (List.map
               (fun (k, v) -> `Assoc [ ("key", key_json k); ("value", expr v) ])
               entries) ) ]
  | ELoaderStorage b -> node [ ("kind", `String "loader_storage"); ("backend", backend b) ]
  | ETaskRunning { tr_owner; tr_id } ->
    node
      [ ("kind", `String "task_running"); ("owner", expr tr_owner); ("id", `String tr_id) ]
  | ESchedule { sc_after; sc_every; sc_name; sc_body } ->
    node
      ([ ("kind", `String "schedule"); ("after_ticks", int_opt sc_after);
         ("every_ticks", int_opt sc_every) ]
      @ (match sc_name with Some n -> [ ("name", `String n) ] | None -> [])
      @ [ ("body", `List (List.map stmt sc_body)) ])

and skin = function
  | SkBuiltin name -> `Assoc [ ("kind", `String "builtin"); ("name", `String name) ]
  | SkPlayer e -> `Assoc [ ("kind", `String "player"); ("expr", expr e) ]
  | SkCustom (texture, signature) ->
    `Assoc
      [ ("kind", `String "custom"); ("texture", expr texture); ("signature", expr signature) ]

and npc_skin = function
  | NpcSkinUsername e -> `Assoc [ ("kind", `String "username"); ("username", expr e) ]
  | NpcSkinTexture (texture, signature) ->
    `Assoc
      [ ("kind", `String "texture"); ("texture", expr texture); ("signature", expr signature) ]

and stmt (s : Ast.stmt) : Yojson.Safe.t =
  let node fields = `Assoc (with_pos s.spos fields) in
  match s.s with
  | SSend (message, target) ->
    node [ ("kind", `String "send"); ("message", expr message); ("target", opt expr target) ]
  | SBroadcast message -> node [ ("kind", `String "broadcast"); ("message", expr message) ]
  | STeleport (entity, target) ->
    node [ ("kind", `String "teleport"); ("entity", expr entity); ("target", expr target) ]
  | SHalt -> node [ ("kind", `String "halt") ]
  | SCancelEvent -> node [ ("kind", `String "cancel_event") ]
  | SIf (condition, then_branch, else_branch) ->
    node
      [ ("kind", `String "if"); ("condition", expr condition); ("then", stmt then_branch);
        ("else", opt stmt else_branch) ]
  | SBlock statements ->
    node [ ("kind", `String "block"); ("statements", `List (List.map stmt statements)) ]
  | SAssign (target, value) ->
    node [ ("kind", `String "assign"); ("target", `String target); ("value", expr value) ]
  | SSetProp (target, name, value) ->
    node
      [ ("kind", `String "set_prop"); ("target", expr target); ("name", `String name);
        ("value", expr value) ]
  | SLoop (count, var, body) ->
    node
      [ ("kind", `String "loop"); ("count", expr count); ("var", opt str var);
        ("body", stmt body) ]
  | SWhile (condition, body) ->
    node [ ("kind", `String "while"); ("condition", expr condition); ("body", stmt body) ]
  | SForeach { fe_var; fe_limit; fe_iter; fe_body } ->
    node
      [ ("kind", `String "foreach"); ("var", `String fe_var); ("limit", opt expr fe_limit);
        ("iterable", expr fe_iter); ("body", stmt fe_body) ]
  | SForeachMap { fm_key; fm_val; fm_map; fm_body } ->
    node
      [ ("kind", `String "foreach_map"); ("key", `String fm_key); ("value", `String fm_val);
        ("map", expr fm_map); ("body", stmt fm_body) ]
  | SCall (name, args) ->
    node
      [ ("kind", `String "call"); ("name", `String name); ("args", `List (List.map expr args)) ]
  | SCallOriginal -> node [ ("kind", `String "call_original") ]
  | SMethodCall (recv, name, args) ->
    node
      [ ("kind", `String "method_call_stmt"); ("receiver", expr recv); ("name", `String name);
        ("args", `List (List.map expr args)) ]
  | SReturn value -> node [ ("kind", `String "return"); ("value", opt expr value) ]
  | SWait (amount, unit) ->
    node [ ("kind", `String "wait"); ("amount", expr amount); ("unit", `String unit) ]
  | SSpawn (name, args) ->
    node
      [ ("kind", `String "spawn");
        ( "call",
          `Assoc [ ("name", `String name); ("args", `List (List.map expr args)) ] ) ]
  | SAsyncBlock body ->
    node [ ("kind", `String "async_block"); ("body", `List (List.map stmt body)) ]
  | SOpenGui go -> node (("kind", `String "open_gui") :: gui_open_fields go)
  | SReplaceGui go -> node (("kind", `String "replace_gui") :: gui_open_fields go)
  | SCloseGui target -> node [ ("kind", `String "close_gui"); ("target", expr target) ]
  | SGuiBack target -> node [ ("kind", `String "gui_back"); ("target", expr target) ]
  | SShowScoreboard (name, target) ->
    node [ ("kind", `String "show_scoreboard"); ("name", `String name); ("target", expr target) ]
  | SHideScoreboard target ->
    node [ ("kind", `String "hide_scoreboard"); ("target", expr target) ]
  | SUpdateScoreboard target ->
    node [ ("kind", `String "update_scoreboard"); ("target", expr target) ]
  | SShowTablist (name, target) ->
    node [ ("kind", `String "show_tablist"); ("name", `String name); ("target", expr target) ]
  | SHideTablist target -> node [ ("kind", `String "hide_tablist"); ("target", expr target) ]
  | SSetTablistPart (part, value, target) ->
    node
      [ ("kind", `String "set_tablist_part"); ("part", `String part); ("value", expr value);
        ("target", expr target) ]
  | STitle { t_title; t_subtitle; t_target; t_fade_in; t_stay; t_fade_out } ->
    node
      [ ("kind", `String "title"); ("title", expr t_title); ("subtitle", opt expr t_subtitle);
        ("target", expr t_target); ("fade_in", int_opt t_fade_in); ("stay", int_opt t_stay);
        ("fade_out", int_opt t_fade_out) ]
  | SClearTitle target -> node [ ("kind", `String "clear_title"); ("target", expr target) ]
  | SActionbar { ab_text; ab_target; ab_duration } ->
    node
      [ ("kind", `String "actionbar"); ("text", expr ab_text); ("target", expr ab_target);
        ("duration", int_opt ab_duration) ]
  | SShowBossbar (name, target) ->
    node [ ("kind", `String "show_bossbar"); ("name", `String name); ("target", expr target) ]
  | SHideBossbar (name, target) ->
    node [ ("kind", `String "hide_bossbar"); ("name", `String name); ("target", expr target) ]
  | SSetBossbarPart { bp_name; bp_part; bp_value; bp_target } ->
    node
      [ ("kind", `String "set_bossbar_part"); ("name", `String bp_name);
        ("part", `String bp_part); ("value", expr bp_value); ("target", expr bp_target) ]
  | SBelowname (text, target) ->
    node [ ("kind", `String "belowname"); ("text", expr text); ("target", expr target) ]
  | SSetBelownameScore (value, target) ->
    node [ ("kind", `String "set_belowname_score"); ("value", expr value); ("target", expr target) ]
  | SClearBelowname target ->
    node [ ("kind", `String "clear_belowname"); ("target", expr target) ]
  | SLine text -> node [ ("kind", `String "line"); ("text", expr text) ]
  | SBlank -> node [ ("kind", `String "blank") ]
  | SEntry (text, sk) -> node [ ("kind", `String "entry"); ("text", expr text); ("skin", skin sk) ]
  | SFill sk -> node [ ("kind", `String "fill"); ("skin", skin sk) ]
  | SPersistSet (name, subject, value) ->
    node
      [ ("kind", `String "persist_set"); ("name", `String name); ("subject", opt expr subject);
        ("value", expr value) ]
  | SGiveItem { gi_id; gi_target; gi_amount } ->
    node
      [ ("kind", `String "give_item"); ("id", expr gi_id); ("target", expr gi_target);
        ("amount", opt expr gi_amount) ]
  | SSpawnMob { sm_target; sm_at; sm_as } ->
    (* §2: by-type spawn carries the nominal type name and the resolved runtime
       id; by-id spawn carries the dynamic id expression *)
    let target_fields =
      match sm_target with
      | MSByType t -> [ ("type_name", `String t.mst_name); ("id", `String t.mst_id) ]
      | MSById e -> [ ("id", expr e) ]
    in
    node
      ((("kind", `String "spawn_mob") :: target_fields)
      @ [ ("at", expr sm_at); ("as", opt str sm_as) ])
  | SDespawnMob target -> node [ ("kind", `String "despawn_mob"); ("target", expr target) ]
  | SSetNametag { nt_part; nt_target; nt_value; nt_viewer } ->
    node
      [ ("kind", `String "set_nametag"); ("part", opt str nt_part); ("target", expr nt_target);
        ("value", expr nt_value); ("viewer", opt expr nt_viewer) ]
  | SResetNametag { rn_target; rn_viewer } ->
    node
      [ ("kind", `String "reset_nametag"); ("target", expr rn_target);
        ("viewer", opt expr rn_viewer) ]
  | SSendPacket { sp_name; sp_fields; sp_target } ->
    node
      [ ("kind", `String "send_packet"); ("name", `String sp_name);
        ("fields", `Assoc (List.map (fun (k, v) -> (k, expr v)) sp_fields));
        ("target", expr sp_target) ]
  | SCancelPacket -> node [ ("kind", `String "cancel_packet") ]
  | SShowDisplay { sh_display; sh_target } ->
    node
      [ ("kind", `String "show_display"); ("display", expr sh_display);
        ("target", expr sh_target) ]
  | SHideDisplay { hi_display; hi_target } ->
    node
      [ ("kind", `String "hide_display"); ("display", expr hi_display);
        ("target", expr hi_target) ]
  | SMountDisplay { mo_display; mo_entity } ->
    node
      [ ("kind", `String "mount_display"); ("display", expr mo_display);
        ("entity", expr mo_entity) ]
  | STeleportDisplay { tp_display; tp_to } ->
    node
      [ ("kind", `String "teleport_display"); ("display", expr tp_display);
        ("to", expr tp_to) ]
  | SDestroyDisplay display ->
    node [ ("kind", `String "destroy_display"); ("display", expr display) ]
  | SReply { rp_code; rp_body } ->
    node [ ("kind", `String "reply"); ("code", opt expr rp_code); ("body", expr rp_body) ]
  | SPlaySong { ps_song; ps_target; ps_tick; ps_at; ps_radius } ->
    node
      [ ("kind", `String "play_song"); ("song", expr ps_song); ("target", opt expr ps_target);
        ("tick", opt expr ps_tick); ("at", opt expr ps_at); ("radius", opt expr ps_radius) ]
  | SPauseSong target -> node [ ("kind", `String "pause_song"); ("target", expr target) ]
  | SResumeSong target -> node [ ("kind", `String "resume_song"); ("target", expr target) ]
  | SStopSong target -> node [ ("kind", `String "stop_song"); ("target", expr target) ]
  | SBroadcastSong song -> node [ ("kind", `String "broadcast_song"); ("song", expr song) ]
  | SSongVolume { vo_target; vo_volume } ->
    node
      [ ("kind", `String "song_volume"); ("target", expr vo_target);
        ("volume", expr vo_volume) ]
  | SFadeSong { fa_target; fa_volume; fa_ticks } ->
    node
      [ ("kind", `String "fade_song"); ("target", expr fa_target); ("volume", expr fa_volume);
        ("ticks", `Int fa_ticks) ]
  | SSetBlock { bl_at; bl_block } ->
    node [ ("kind", `String "set_block"); ("at", expr bl_at); ("block", expr bl_block) ]
  | SFillBlocks { fb_from; fb_to; fb_block } ->
    node
      [ ("kind", `String "fill_blocks"); ("from", expr fb_from); ("to", expr fb_to);
        ("block", expr fb_block) ]
  | SPlaySound { sn_sound; sn_target; sn_at; sn_volume; sn_pitch } ->
    node
      [ ("kind", `String "play_sound"); ("sound", expr sn_sound); ("target", expr sn_target);
        ("at", opt expr sn_at); ("volume", opt expr sn_volume); ("pitch", opt expr sn_pitch) ]
  | SStopSound { so_sound; so_target } ->
    node
      [ ("kind", `String "stop_sound"); ("sound", opt expr so_sound);
        ("target", expr so_target) ]
  | SSpawnParticle { pa_particle; pa_at; pa_count; pa_offset; pa_speed; pa_viewer } ->
    node
      [ ("kind", `String "spawn_particle"); ("particle", expr pa_particle); ("at", expr pa_at);
        ("count", opt expr pa_count);
        ("offset_x", opt (fun (x, _, _) -> expr x) pa_offset);
        ("offset_y", opt (fun (_, y, _) -> expr y) pa_offset);
        ("offset_z", opt (fun (_, _, z) -> expr z) pa_offset);
        ("speed", opt expr pa_speed); ("viewer", opt expr pa_viewer) ]
  | SSetServerMotd value -> node [ ("kind", `String "set_server_motd"); ("value", expr value) ]
  | SShowToast { to_title; to_description; to_icon; to_frame; to_target } ->
    node
      [ ("kind", `String "show_toast"); ("title", expr to_title);
        ("description", opt expr to_description); ("icon", opt expr to_icon);
        ("frame", opt (fun (f, _) -> `String f) to_frame); ("target", expr to_target) ]
  | SDrawPixel { px_canvas; px_x; px_y; px_color } ->
    node
      [ ("kind", `String "draw_pixel"); ("canvas", expr px_canvas); ("x", expr px_x);
        ("y", expr px_y); ("color", expr px_color) ]
  | SDrawRect { rc_canvas; rc_x1; rc_y1; rc_x2; rc_y2; rc_color } ->
    node
      [ ("kind", `String "draw_rect"); ("canvas", expr rc_canvas); ("x1", expr rc_x1);
        ("y1", expr rc_y1); ("x2", expr rc_x2); ("y2", expr rc_y2); ("color", expr rc_color) ]
  | SDrawText { tx_canvas; tx_x; tx_y; tx_text; tx_color } ->
    node
      [ ("kind", `String "draw_text"); ("canvas", expr tx_canvas); ("x", expr tx_x);
        ("y", expr tx_y); ("text", expr tx_text); ("color", expr tx_color) ]
  | SGiveMap { gm_canvas; gm_target } ->
    node
      [ ("kind", `String "give_map"); ("canvas", expr gm_canvas); ("target", expr gm_target) ]
  | STaskSet { tk_owner; tk_id; tk_value } ->
    node
      [ ("kind", `String "task_set"); ("owner", expr tk_owner); ("id", `String tk_id);
        ("value", expr tk_value) ]
  | STaskCancel { tc_owner; tc_id } ->
    node [ ("kind", `String "task_cancel"); ("owner", expr tc_owner); ("id", `String tc_id) ]
  | SPlaceBlock { pb_block; pb_at } ->
    node [ ("kind", `String "place"); ("block", expr pb_block); ("location", expr pb_at) ]
  | SRemoveBlock loc ->
    node [ ("kind", `String "remove_block"); ("location", expr loc) ]
  | SCancelSchedule schedule ->
    node [ ("kind", `String "cancel_schedule"); ("schedule", expr schedule) ]
  | SStop -> node [ ("kind", `String "stop") ]
  | SRepeat { rp_count; rp_every; rp_body } ->
    node
      [ ("kind", `String "repeat"); ("count", expr rp_count); ("every_ticks", int_opt rp_every);
        ("body", `List (List.map stmt rp_body)) ]
  | SCreateWorld { cw_name; cw_readonly; cw_loader } ->
    node
      [ ("kind", `String "create_world"); ("name", expr cw_name);
        ("readonly", `Bool cw_readonly); ("loader", expr cw_loader) ]
  | SLoadWorld { lw_name; lw_loader } ->
    node [ ("kind", `String "load_world"); ("name", expr lw_name); ("loader", expr lw_loader) ]
  | SUnloadWorld { uw_name; uw_save; uw_teleport } ->
    node
      [ ("kind", `String "unload_world"); ("name", expr uw_name); ("save", `Bool uw_save);
        ("teleport", opt expr uw_teleport) ]
  | SSaveWorld name -> node [ ("kind", `String "save_world"); ("name", expr name) ]
  | SCloneWorld { cl_from; cl_to; cl_loader } ->
    node
      [ ("kind", `String "clone_world"); ("from", expr cl_from); ("to", expr cl_to);
        ("loader", expr cl_loader) ]
  | SDeleteWorld { dw_name; dw_loader } ->
    node
      [ ("kind", `String "delete_world"); ("name", expr dw_name); ("loader", expr dw_loader) ]
  | SImportWorld { iw_path; iw_name; iw_loader } ->
    node
      [ ("kind", `String "import_world"); ("path", expr iw_path); ("name", expr iw_name);
        ("loader", expr iw_loader) ]
  | SSpawnEntity { se_type; se_at; se_as } ->
    node
      [ ("kind", `String "spawn_entity"); ("type", expr se_type); ("at", expr se_at);
        ("as", opt str se_as) ]
  | SRemoveEntity target -> node [ ("kind", `String "remove_entity"); ("target", expr target) ]
  | SMount { m_rider; m_vehicle } ->
    node
      [ ("kind", `String "mount_entity"); ("rider", expr m_rider);
        ("vehicle", expr m_vehicle) ]
  | SDismount target -> node [ ("kind", `String "dismount_entity"); ("target", expr target) ]
  | SLaunchProjectile { lp_type; lp_from; lp_velocity; lp_speed; lp_as } ->
    node
      [ ("kind", `String "launch_projectile"); ("type", expr lp_type); ("from", expr lp_from);
        ("velocity", opt expr lp_velocity); ("speed", opt expr lp_speed);
        ("as", opt str lp_as) ]
  | SDispenseFrom loc -> node [ ("kind", `String "dispense_from"); ("from", expr loc) ]
  | SShowHologram (name, target) ->
    node [ ("kind", `String "show_hologram"); ("name", `String name); ("target", expr target) ]
  | SHideHologram (name, target) ->
    node [ ("kind", `String "hide_hologram"); ("name", `String name); ("target", expr target) ]
  | SSetHologramLine { shl_name; shl_index; shl_value } ->
    node
      [ ("kind", `String "set_hologram_line"); ("name", `String shl_name);
        ("index", expr shl_index); ("value", expr shl_value) ]
  | SMoveHologram (name, target) ->
    node [ ("kind", `String "move_hologram"); ("name", `String name); ("to", expr target) ]
  | SRemoveHologram name -> node [ ("kind", `String "remove_hologram"); ("name", `String name) ]
  | SSetNpcSkin { sns_name; sns_skin } ->
    node [ ("kind", `String "set_npc_skin"); ("name", `String sns_name); ("skin", npc_skin sns_skin) ]
  | SSetNpcName { snn_name; snn_value } ->
    node [ ("kind", `String "set_npc_name"); ("name", `String snn_name); ("value", expr snn_value) ]
  | SSetNpcLocation { snl_name; snl_value } ->
    node
      [ ("kind", `String "set_npc_location"); ("name", `String snl_name);
        ("value", expr snl_value) ]
  | SRemoveNpc name -> node [ ("kind", `String "remove_npc"); ("name", `String name) ]
  | SShowNpc (name, target) ->
    node [ ("kind", `String "show_npc"); ("name", `String name); ("target", expr target) ]
  | SHideNpc (name, target) ->
    node [ ("kind", `String "hide_npc"); ("name", `String name); ("target", expr target) ]
  | SShowEntity { she_entity; she_target } ->
    node
      [ ("kind", `String "show_entity"); ("entity", expr she_entity);
        ("target", expr she_target) ]
  | SHideEntity { hie_entity; hie_target } ->
    node
      [ ("kind", `String "hide_entity"); ("entity", expr hie_entity);
        ("target", expr hie_target) ]
  | SSetEntityName { sen_entity; sen_value; sen_viewer } ->
    node
      [ ("kind", `String "set_entity_name"); ("entity", expr sen_entity);
        ("value", expr sen_value); ("viewer", expr sen_viewer) ]
  (* --- W-pvp: attribute modifiers + combat effect verbs --- *)
  | SAddModifier { am_id; am_entity; am_attr; am_amount; am_op; _ } ->
    node
      [ ("kind", `String "add_modifier"); ("id", expr am_id); ("entity", expr am_entity);
        ("attribute", `String am_attr); ("amount", expr am_amount);
        ("operation", `String am_op) ]
  | SRemoveModifier { rm_id; rm_entity; rm_attr; _ } ->
    node
      [ ("kind", `String "remove_modifier"); ("id", expr rm_id); ("entity", expr rm_entity);
        ("attribute", `String rm_attr) ]
  | SDamage { dm_target; dm_amount; dm_type; dm_source } ->
    node
      [ ("kind", `String "damage"); ("target", expr dm_target); ("amount", expr dm_amount);
        ("damage_type", opt expr dm_type); ("source", opt expr dm_source) ]
  | SKnock { kn_target; kn_from; kn_strength } ->
    node
      [ ("kind", `String "knock"); ("target", expr kn_target); ("from", expr kn_from);
        ("strength", opt expr kn_strength) ]
  | SApplyEffect { ae_effect; ae_amplifier; ae_entity; ae_duration } ->
    node
      [ ("kind", `String "apply_effect"); ("effect", expr ae_effect);
        ("amplifier", expr ae_amplifier); ("entity", expr ae_entity);
        ("duration", expr ae_duration) ]
  | SRemoveEffect { re_effect; re_entity } ->
    node
      [ ("kind", `String "remove_effect"); ("effect", expr re_effect);
        ("entity", expr re_entity) ]
  | SShoot { sh_type; sh_from; sh_velocity; sh_shooter } ->
    node
      [ ("kind", `String "shoot"); ("projectile", expr sh_type); ("from", expr sh_from);
        ("velocity", opt expr sh_velocity); ("shooter", opt expr sh_shooter) ]

and gui_open_fields go =
  [
    ("name", `String go.go_name);
    ("target", expr go.go_target);
    ("init", `Assoc (List.map (fun (k, v) -> (k, expr v)) go.go_init));
  ]

let argument a =
  `Assoc
    (with_pos a.arg_pos
       [ ("name", `String a.arg_name); ("type", data_type a.arg_type);
         ("default", opt str a.arg_default) ])

let statements ss = `List (List.map stmt ss)

let exec_block ex =
  `Assoc [ ("async", `Bool ex.ex_async); ("statements", statements ex.ex_stmts) ]

let command c =
  `Assoc
    (with_pos c.cmd_pos
       [ ("names", `List (List.map str c.names)); ("permission", opt str c.permission);
         ("description", opt str c.description);
         ("arguments", `List (List.map argument c.arguments));
         ("execute", opt exec_block c.execute) ])

let func f =
  `Assoc
    (with_pos f.fn_pos
       [ ("name", `String f.fn_name); ("async", `Bool f.fn_async);
         ("params", `List (List.map param f.params)); ("body", statements f.body) ])

let item_spec spec =
  `Assoc
    [
      ("material", opt expr spec.is_material);
      ("skull", opt expr spec.is_skull);
      ("name", opt expr spec.is_name);
      ("lore", opt (fun items -> `List (List.map expr items)) spec.is_lore);
      ("amount", opt expr spec.is_amount);
      ("glint", opt expr spec.is_glint);
    ]

let fill_value = function
  | FSpec spec -> item_spec spec
  | FExpr e -> expr e

let gui_slot slot =
  `Assoc
    [
      ("slots", `List (List.map (fun i -> `Int i) slot.gs_slots));
      ("item", item_spec slot.gs_item);
      ( "click_handlers",
        `List
          (List.map
             (fun ch ->
               `Assoc [ ("filter", `String ch.ch_filter); ("body", statements ch.ch_body) ])
             slot.gs_clicks) );
      ("refresh", int_opt slot.gs_refresh);
    ]

let gui_editable ed =
  `Assoc
    [
      ("slots", `List (List.map (fun i -> `Int i) ed.ge_slots));
      ("on_change", opt statements ed.ge_on_change);
    ]

let gui_paginate pg =
  `Assoc
    [
      ("source", expr pg.gp_source);
      ("slots", `List (List.map (fun i -> `Int i) pg.gp_slots));
      ("render", item_spec pg.gp_render);
      ("on_click", opt statements pg.gp_on_click);
      ("prev_slot", int_opt pg.gp_prev_slot);
      ("next_slot", int_opt pg.gp_next_slot);
    ]

let gui g =
  `Assoc
    (with_pos g.g_pos
       [
         ("name", `String g.g_name);
         ("rows", `Int g.g_rows);
         ("title", expr g.g_title);
         ("state", `Assoc (List.map (fun (k, v) -> (k, expr v)) g.g_state));
         ("fill", opt fill_value g.g_fill);
         ("border", opt fill_value g.g_border);
         ("slots", `List (List.map gui_slot g.g_slots));
         ("editable", `List (List.map gui_editable g.g_editable));
         ("paginate", opt gui_paginate g.g_paginate);
         ("refresh", int_opt g.g_refresh);
         ("on_open", opt statements g.g_on_open);
         ("on_close", opt statements g.g_on_close);
         ("on_click_fallback", opt statements g.g_on_click);
       ])

let update_spec = function
  | UTicks n -> `Assoc [ ("kind", `String "ticks"); ("value", `Int n) ]
  | UManual -> `Assoc [ ("kind", `String "manual") ]

let scoreboard sb =
  `Assoc
    (with_pos sb.sb_pos
       [
         ("name", `String sb.sb_name);
         ("title", expr sb.sb_title);
         ("update", update_spec sb.sb_update);
         ("numbers", `String sb.sb_numbers);
         ("lines", statements sb.sb_lines);
       ])

let tablist tl =
  `Assoc
    (with_pos tl.tl_pos
       [
         ("name", `String tl.tl_name);
         ("update", update_spec tl.tl_update);
         ("header", opt expr tl.tl_header);
         ("footer", opt expr tl.tl_footer);
         ( "columns",
           `List
             (List.map
                (fun col -> `Assoc (with_pos col.col_pos [ ("body", statements col.col_body) ]))
                tl.tl_columns) );
       ])

let bossbar bb =
  `Assoc
    (with_pos bb.bb_pos
       [
         ("name", `String bb.bb_name);
         ("text", expr bb.bb_text);
         ("progress", expr bb.bb_progress);
         ("color", `String bb.bb_color);
         ("style", `String bb.bb_style);
         ("update", update_spec bb.bb_update);
       ])

(* Simple `${...}` interpolation fragments (dotted paths) are kept embedded in
   the string literal by the parser and resolved by the runtime interpolator,
   so a line like "Hi ${player.name}" never becomes a structured EProp/EVar.
   Per-viewer detection must therefore also scan raw string literals for a
   `${player}` / `${player.<...>}` fragment (root identifier == "player"). *)
let string_interp_references_player s =
  let n = String.length s in
  let is_ident_char c =
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_'
  in
  let rec scan i =
    if i + 1 >= n then false
    else if s.[i] = '$' && s.[i + 1] = '{' then begin
      (* skip leading whitespace inside the braces, then read the root ident *)
      let j = ref (i + 2) in
      while !j < n && (s.[!j] = ' ' || s.[!j] = '\t') do incr j done;
      let start = !j in
      while !j < n && is_ident_char s.[!j] do incr j done;
      let root = String.sub s start (!j - start) in
      (* the fragment references the viewer when its root path is `player` and
         it is a bare var or a property access (player / player.x / player}) *)
      let is_player =
        root = "player"
        && (!j >= n
            || (match s.[!j] with '.' | '}' | ' ' | '\t' -> true | _ -> false))
      in
      is_player || scan (i + 1)
    end
    else scan (i + 1)
  in
  scan 0

(* per-viewer detection (GROUP D): a hologram whose lines interpolate a
   player-scoped path renders per viewer (each viewer gets their own display
   stack, lines re-rendered with 'player' bound), exactly like scoreboards.
   The scan only needs to cover the restricted line-DSL forms
   (line/blank/if/loop/block) plus the expression grammar they can host. *)
let references_player_expr =
  let rec e_p (e : Ast.expr) =
    match e.e with
    | EVar "player" -> true
    | EString s -> string_interp_references_player s
    | EProp (t, _) -> e_p t
    | EBinary (_, a, b) -> e_p a || e_p b
    | EUnary (_, a) -> e_p a
    | ECall (_, args) | EList args -> List.exists e_p args
    | EMethod (recv, _, args) -> e_p recv || List.exists e_p args
    | EPersistGet (_, s) -> Option.fold ~none:false ~some:e_p s
    | EMap fs -> List.exists (fun (_, v) -> e_p v) fs
    | EMapLit es -> List.exists (fun (_, v) -> e_p v) es
    | EStructNew (_, fs) -> List.exists (fun (_, v) -> e_p v) fs
    | ELambda { lam_body; _ } -> List.exists s_p lam_body
    | ESchedule { sc_body; _ } -> List.exists s_p sc_body
    | ETaskRunning { tr_owner; _ } -> e_p tr_owner
    | ENumber _ | EBool _ | ENone | EVar _ | EType _ | EAllPlayers
    | ELoaderStorage _ ->
      false
  and s_p (s : Ast.stmt) =
    match s.s with
    | SLine e -> e_p e
    | SIf (c, t, el) ->
      e_p c || s_p t || (match el with Some e -> s_p e | None -> false)
    | SLoop (c, _, b) -> e_p c || s_p b
    | SForeach { fe_iter; fe_limit; fe_body; _ } ->
      e_p fe_iter || Option.fold ~none:false ~some:e_p fe_limit || s_p fe_body
    | SBlock ss -> List.exists s_p ss
    | _ -> false
  in
  e_p

let hologram_per_viewer lines =
  let rec s_p (s : Ast.stmt) =
    match s.s with
    | SLine e -> references_player_expr e
    | SIf (c, t, el) ->
      references_player_expr c || s_p t || (match el with Some e -> s_p e | None -> false)
    | SLoop (c, _, b) -> references_player_expr c || s_p b
    | SForeach { fe_iter; fe_limit; fe_body; _ } ->
      references_player_expr fe_iter
      || Option.fold ~none:false ~some:references_player_expr fe_limit
      || s_p fe_body
    | SBlock ss -> List.exists s_p ss
    | _ -> false
  in
  List.exists s_p lines

(* first-class inline handlers (W-inline-handlers): emitted as a "handlers"
   object keyed by event name; each entry carries the user binder names (in
   order, for the runtime dispatcher to bind the event args) and the body.
   Additive — the key is omitted entirely when a declaration has none, so
   handler-free declarations stay byte-identical. *)
(* the bare variables a handler binds: the receiver noun ("self") first, then the
   event's canonical arg names — the same set the typechecker binds. *)
let handler_params kind event =
  match Registry.find_handler kind event with
  | Some sg -> List.map (fun (n, _) -> `String n) sg.h_params
  | None -> []

let inline_handlers kind (hs : Ast.inline_handler list) =
  `Assoc
    (List.map
       (fun (h : Ast.inline_handler) ->
         ( h.ih_event,
           `Assoc
             [
               ("self", `String (Registry.decl_noun kind));
               ("params", `List (handler_params kind h.ih_event));
               ("body", statements h.ih_body);
             ] ))
       hs)

let handlers_field kind = function [] -> [] | hs -> [ ("handlers", inline_handlers kind hs) ]

let hologram h =
  `Assoc
    (with_pos h.h_pos
       ([
          ("name", `String h.h_name);
          ("location", expr h.h_location);
          ("billboard", `String h.h_billboard);
          ("scale", opt expr h.h_scale);
          ("update", update_spec h.h_update);
          ("per_viewer", `Bool (hologram_per_viewer h.h_lines));
          ("lines", statements h.h_lines);
        ]
       @ (match h.h_viewable with Some v -> [ ("viewable", `Bool v) ] | None -> [])
       @ handlers_field Registry.KHologram h.h_handlers))

let npc n =
  `Assoc
    (with_pos n.n_pos
       ([
          ("name", `String n.n_name);
          ("location", expr n.n_location);
          ("display_name", opt expr n.n_display_name);
          ("skin", opt npc_skin n.n_skin);
          ("look_at_players", `Bool n.n_look_at_players);
        ]
       @ (match n.n_viewable with Some v -> [ ("viewable", `Bool v) ] | None -> [])
       @ [
          ( "on_click",
            opt
              (fun body ->
                `Assoc
                  [ ("self", `String "npc"); ("params", `List [ `String "player" ]);
                    ("body", statements body) ])
              n.n_on_click );
          ( "on_left_click",
            opt
              (fun body ->
                `Assoc
                  [ ("self", `String "npc"); ("params", `List [ `String "player" ]);
                    ("body", statements body) ])
              n.n_on_left_click );
        ]
       @ handlers_field Registry.KNpc n.n_handlers))

let server sv =
  let auth =
    match sv.sv_auth with
    | AuthOffline -> `Assoc [ ("kind", `String "offline"); ("secret", `Null) ]
    | AuthMojang -> `Assoc [ ("kind", `String "mojang"); ("secret", `Null) ]
    | AuthVelocity secret -> `Assoc [ ("kind", `String "velocity"); ("secret", `String secret) ]
    | AuthBungeecord -> `Assoc [ ("kind", `String "bungeecord"); ("secret", `Null) ]
  in
  (* phase-6 keys are additive: only present when used, so pre-phase-6
     scripts emit byte-identical server JSON *)
  `Assoc
    (with_pos sv.sv_pos
       ([
          ("auth", auth);
          ("host", `String (match sv.sv_host with Some h -> h | None -> "0.0.0.0"));
          ("port", `Int (match sv.sv_port with Some p -> p | None -> 25565));
          ("brand", opt str sv.sv_brand);
          ("motd", opt str sv.sv_motd);
        ]
       @ (match sv.sv_http with
         | None -> []
         | Some hc ->
           [ ("http", `Assoc [ ("port", `Int hc.hc_port); ("bind", `String hc.hc_bind) ]) ])
       @ (match sv.sv_favicon with
         | None -> []
         | Some f -> [ ("favicon", `String f) ])
       @ (if sv.sv_permissions = [] then []
          else
            [
              ( "permissions",
                `Assoc
                  (List.map
                     (fun (user, perms) -> (user, `List (List.map str perms)))
                     sv.sv_permissions) );
            ])
       @ (if sv.sv_open_to_lan then [ ("open_to_lan", `Bool true) ] else [])
       (* lighting defaults to true; emit the key only when disabled so
          pre-existing server scripts stay byte-identical (additive) *)
       @ (if sv.sv_lighting then [] else [ ("lighting", `Bool false) ])
       @
       match sv.sv_fishing with
       | None -> []
       | Some fc ->
         [
           ( "fishing",
             `Assoc
               [
                 ("min_bite_ticks", `Int fc.fi_min_bite);
                 ("max_bite_ticks", `Int fc.fi_max_bite);
               ] );
         ]))

let storage sc =
  `Assoc
    (with_pos sc.st_pos
       [ ("backend", backend sc.st_backend); ("flush_ticks", `Int sc.st_flush_ticks) ])

(* Numeric declaration scalars (mob health/damage/speed, drop chance/
   amount, item amount/attributes) load through SwoftJsonLoader.scalarNumber,
   which only accepts literal nodes: constant-fold composite arithmetic the
   checker has already validated. Plain literals (including unary-minus
   literals, which the loader handles) are emitted untouched so existing
   artifacts stay byte-identical. *)
let const_number (e : Ast.expr) : Yojson.Safe.t =
  let is_literal =
    match e.e with
    | ENumber _ -> true
    | EUnary ("NEGATE", { e = ENumber _; _ }) -> true
    | _ -> false
  in
  if is_literal then expr e
  else
    match Ast.fold_number e with
    | Some f ->
      let integer = Float.is_integer f && Float.abs f < 1e15 in
      let value =
        if integer then string_of_int (int_of_float f) else Printf.sprintf "%.17g" f
      in
      expr { e with e = ENumber { value; integer } }
    | None -> expr e

let kv_entries entries = `Assoc (List.map (fun (k, _, v) -> (k, const_number v)) entries)

(* on_click(<filter>) sugar (phase 9): filtered use-item handlers, emitted in
   the same click-handler shape as gui slot clicks *)
let item_click_handler ch =
  `Assoc [ ("filter", `String ch.ch_filter); ("body", statements ch.ch_body) ]

let item_decl it =
  `Assoc
    (with_pos it.it_pos
       ([
          ("type_name", `String it.it_tyname);
          ("id", `String it.it_id);
          ("material", opt str it.it_material);
          ("skull", opt str it.it_skull);
          ("name", opt expr it.it_name);
          ("rarity", opt (fun (r, _) -> `String r) it.it_rarity);
          ("glint", opt expr it.it_glint);
          ("amount", opt const_number it.it_amount);
          ("lore", opt statements it.it_lore);
          ("attributes", kv_entries it.it_attributes);
          (* nested NBT: scalars, EList lists, EMap compounds — expr already
             renders {"kind":"list"|"map"} for the composite cases (phase 9 §2) *)
          ("tags", `Assoc (List.map (fun (k, v) -> (k, expr v)) it.it_tags));
          ("on_click", `List (List.map item_click_handler it.it_on_click));
        ]
       @ handlers_field Registry.KItem it.it_handlers))

let mob_drop dr =
  `Assoc
    (with_pos dr.dr_pos
       [
         ("item", `String dr.dr_id);
         ("chance", const_number dr.dr_chance);
         ("amount", opt const_number dr.dr_amount);
       ])

(* typed mob tag block (W-viewers §2): each entry is either a type declaration
   (an empty, typed, indexable store) or a value init (type inferred). Emitted
   only when non-empty so pre-existing mob scripts stay byte-identical. *)
let mob_tag_spec = function
  | MTType dt -> `Assoc [ ("kind", `String "type"); ("type", data_type dt) ]
  | MTValue e -> `Assoc [ ("kind", `String "value"); ("value", expr e) ]

let mob_tags ts =
  `Assoc (List.map (fun (t : mob_tag) -> (t.mt_name, mob_tag_spec t.mt_spec)) ts)

let mob_decl mb =
  `Assoc
    (with_pos mb.mb_pos
       ([
          ("type_name", `String mb.mb_tyname);
          ("id", `String mb.mb_id);
          ("type", opt (fun (t, _) -> `String t) mb.mb_type);
          ("name", opt expr mb.mb_name);
          ("health", opt const_number mb.mb_health);
          ("damage", opt const_number mb.mb_damage);
          ("speed", opt const_number mb.mb_speed);
          ("ai", opt (fun (a, _) -> `String a) mb.mb_ai);
          ("drops", `List (List.map mob_drop mb.mb_drops));
          ("on_spawn", opt statements mb.mb_on_spawn);
          ("on_death", opt statements mb.mb_on_death);
          ("on_attack", opt statements mb.mb_on_attack);
        ]
       (* viewable + typed tags are additive: only present when declared, so
          pre-existing mob scripts emit byte-identical JSON (W-viewers) *)
       @ (match mb.mb_viewable with Some v -> [ ("viewable", `Bool v) ] | None -> [])
       @ (if mb.mb_tags = [] then [] else [ ("tags", mob_tags mb.mb_tags) ])
       (* on_hit is additive: only present when declared, so pre-existing mob
          scripts emit byte-identical JSON *)
       @ (match mb.mb_on_hit with
         | None -> []
         | Some ss ->
           [ ("on_hit", `Assoc [ ("attacker", `String "attacker"); ("body", statements ss) ]) ])
       @ handlers_field Registry.KMob mb.mb_handlers))

let packet_listener pk =
  `Assoc
    (with_pos pk.pk_pos
       [ ("name", `String pk.pk_name); ("execute", opt exec_block pk.pk_execute) ])

let api_decl (a : api_decl) =
  `Assoc
    (with_pos a.api_pos
       [
         ("path", `String a.api_path);
         ("method", opt (fun (m, _) -> `String (String.uppercase_ascii m)) a.api_method);
         ("execute", opt exec_block a.api_execute);
       ])

let sched_decl (sd : sched_decl) =
  `Assoc
    (with_pos sd.sd_pos
       ([ ("every_ticks", `Int sd.sd_every) ]
       @ (match sd.sd_name with Some n -> [ ("name", `String n) ] | None -> [])
       @ [ ("body", statements sd.sd_body) ]))

(* --- phase-8 fishing loot tables --- *)

let fishing_catch (c : fishing_catch) =
  `Assoc
    (with_pos c.fc_pos
       [
         ("kind", `String (if c.fc_mob then "mob" else "item"));
         ("id", `String c.fc_id);
         ("weight", const_number c.fc_weight);
         ("message", opt str c.fc_message);
       ])

let fishing_loot (fl : fishing_loot) =
  `Assoc
    (with_pos fl.fl_pos
       [
         ("name", `String fl.fl_name);
         ("medium", opt (fun (m, _) -> `String m) fl.fl_medium);
         ("world", opt str fl.fl_world);
         ("catches", `List (List.map fishing_catch fl.fl_catches));
       ])

(* §1 structs: a struct declaration emits its name and its fields (each with a
   resolved type, an optional default, and — only when set — the phase-3
   reactive marker, kept off by default so the shape stays minimal). *)
let struct_field (f : struct_field) =
  `Assoc
    (with_pos f.srf_pos
       ([ ("name", `String f.srf_name); ("type", data_type f.srf_type);
          ("default", opt expr f.srf_default) ]
       @ (if f.srf_reactive then [ ("reactive", `Bool true) ] else [])))

(* §4 a reactive field block: the subject field, its resolved base-subject type
   (the vocabulary picker), and the instance handlers keyed by event name. Each
   handler entry carries the bare subject-field name, the event's canonical arg
   names (bound as bare vars alongside the struct's other fields), and the body.
   The runtime dispatches these last (§4.3 precedence) for any instance reachable
   from a persistent root (§4.2 liveness). *)
let struct_reactive_block (sd : struct_decl) (r : struct_reactive) =
  let field_dt =
    match List.find_opt (fun (f : struct_field) -> f.srf_name = r.sr_field) sd.su_fields with
    | Some f -> Some f.srf_type
    | None -> None
  in
  let rk =
    match field_dt with
    | Some dt -> Registry.receiver_kind_of_ty (Tc_types.ty_of_dt dt)
    | None -> None
  in
  let subject = match rk with Some k -> Registry.receiver_name k | None -> "" in
  let handler (h : inline_handler) =
    let params =
      match rk with
      | Some k -> (
        match Registry.find_receiver_method k h.ih_event with
        | Some sg -> List.map (fun (n, _) -> `String n) sg.h_params
        | None -> [])
      | None -> []
    in
    ( h.ih_event,
      `Assoc
        [ ("subject", `String r.sr_field); ("params", `List params);
          ("body", statements h.ih_body) ] )
  in
  `Assoc
    (with_pos r.sr_pos
       [ ("field", `String r.sr_field); ("subject", `String subject);
         ("handlers", `Assoc (List.map handler r.sr_handlers)) ])

(* §5 a versioned migration block: the target schema version it upgrades to and
   the statement body. The body reads the raw prior fields via the `raw` map and
   assigns the current struct's fields as bare vars; the runtime runs these in
   ascending version order for any stored row older than the current schema. *)
let struct_migration (m : struct_migration) =
  `Assoc (with_pos m.sm_pos [ ("to", `Int m.sm_version); ("body", statements m.sm_body) ])

let struct_decl (sd : struct_decl) =
  `Assoc
    (with_pos sd.su_pos
       ([ ("name", `String sd.su_tyname) ]
       (* §5 schema version: emitted only when non-default so the runtime stamps
          __schema and applies migrations; absence means version 1. *)
       @ (if sd.su_schema <> 1 then [ ("schema", `Int sd.su_schema) ] else [])
       @ [ ("fields", `List (List.map struct_field sd.su_fields)) ]
       @ (match sd.su_reactive with
          | [] -> []
          | rs -> [ ("reactive", `List (List.map (struct_reactive_block sd) rs)) ])
       @
       match sd.su_migrations with
       | [] -> []
       | ms -> [ ("migrations", `List (List.map struct_migration ms)) ]))

let persistent pd =
  `Assoc
    (with_pos pd.pd_pos
       [
         ("name", `String pd.pd_name);
         ("subject", opt data_type pd.pd_subject);
         ("type", data_type pd.pd_type);
         ("default", expr pd.pd_default);
       ])

(* Per-script content keys, shared between the flat shape and each entry of
   the bundle's "modules" array. In modular mode every symbol declaration
   additionally carries its "exported" flag; flat emission stays byte-
   identical to the pre-module compiler. *)
(* --- W-blocks: block_handler / placement_rule --- *)
let block_cb cbs (cb : block_cb) =
  (* the hook's canonical arg names, bound as bare variables in scope *)
  let params =
    match Registry.find_block_cb cbs cb.cb_name with
    | Some sg -> List.map (fun (n, _) -> `String n) sg.bcb_params
    | None -> []
  in
  `Assoc
    (with_pos cb.cb_pos
       [
         ("name", `String cb.cb_name);
         ("params", `List params);
         ("body", `List (List.map stmt cb.cb_body));
       ])

let block_handler_decl (bh : block_handler_decl) =
  `Assoc
    (with_pos bh.bh_pos
       [ ("id", `String bh.bh_id);
         ("callbacks", `List (List.map (block_cb Registry.block_handler_cbs) bh.bh_callbacks)) ])

let placement_rule_decl (pr : placement_rule_decl) =
  `Assoc
    (with_pos pr.pr_pos
       [
         ("id", `String pr.pr_id);
         ("self_replaceable", `Bool pr.pr_self_replaceable);
         ("callbacks", `List (List.map (block_cb Registry.placement_rule_cbs) pr.pr_callbacks));
       ])

(* OOP receiver blocks compile DOWN to the same event-dispatch JSON the removed
   flat `event { }` form emitted, so the runtime EventRegistrar target is
   unchanged. Each receiver method becomes one entry in the top-level "events"
   array carrying { name, priority, execute } exactly as the flat form did, plus
   the additive "receiver" (the base type, for instance filtering) and "params"
   (the user's positional binder names, so the dispatcher can bind the event
   args). The event "name" goes through `canonical_event_name`, matching the flat
   form; methods with no distinct catalog event (they ride the inline-handler /
   NPC / hologram / mob-forwarding runtimes) get a `<Receiver>.<method>`
   identifier. One method maps to one event; fan-out across receivers is naturally
   expressed as multiple entries sharing an event name (the runtime attaches one
   EventNode listener per entry, as with multiple flat handlers today). *)
let receiver_event (rc_type : string) (rk : Registry.receiver_kind) (h : Ast.inline_handler) =
  let name =
    match Registry.receiver_method_event rk h.ih_event with
    | Some e -> Registry.canonical_event_name e
    | None -> rc_type ^ "." ^ h.ih_event
  in
  (* the bare variables the method binds: the receiver noun first, then the
     event's canonical arg names (the same set the typechecker binds) *)
  let params =
    match Registry.find_receiver_method rk h.ih_event with
    | Some sg -> List.map (fun (n, _) -> `String n) sg.h_params
    | None -> []
  in
  `Assoc
    (with_pos h.ih_pos
       [ ("name", `String name); ("receiver", `String rc_type); ("priority", `Int 0);
         ("self", `String (Registry.receiver_noun rk));
         ("params", `List params);
         ("execute",
          `Assoc [ ("async", `Bool false); ("statements", statements h.ih_body) ]) ])

let receiver_events (rs : Ast.receiver_decl list) =
  List.concat_map
    (fun (r : Ast.receiver_decl) ->
      match Registry.receiver_kind_of_name r.rc_type with
      | None -> [] (* unknown receiver: the typechecker has already errored *)
      | Some rk -> List.map (receiver_event r.rc_type rk) r.rc_methods)
    rs

let script_fields ~modular (s : Ast.script) =
  (* additive keys: only present when the feature is used, so pre-persistence
     scripts emit byte-identical JSON *)
  let mark exported json =
    if not modular then json
    else
      match json with
      | `Assoc fields -> `Assoc (fields @ [ ("exported", `Bool exported) ])
      | other -> other
  in
  let persistence =
    if s.storages = [] && s.persistents = [] then []
    else
      [
        ("storage", opt storage (match s.storages with [] -> None | sc :: _ -> Some sc));
        ("persistents", `List (List.map persistent s.persistents));
      ]
  in
  let content =
    (if s.structs = [] then []
     else
       [ ("structs", `List (List.map (fun sd -> mark sd.su_exported (struct_decl sd)) s.structs)) ])
    @ (if s.holograms = [] then []
     else
       [ ("holograms", `List (List.map (fun h -> mark h.h_exported (hologram h)) s.holograms)) ])
    @ (if s.npcs = [] then []
       else [ ("npcs", `List (List.map (fun n -> mark n.n_exported (npc n)) s.npcs)) ])
    @ (if s.items = [] then []
     else
       [ ("items", `List (List.map (fun it -> mark it.it_exported (item_decl it)) s.items)) ])
    @ (if s.mobs = [] then []
       else
         [ ("mobs", `List (List.map (fun mb -> mark mb.mb_exported (mob_decl mb)) s.mobs)) ])
    @ (if s.packet_listeners = [] then []
       else [ ("packet_listeners", `List (List.map packet_listener s.packet_listeners)) ])
    @ (if s.apis = [] then [] else [ ("apis", `List (List.map api_decl s.apis)) ])
    @ (if s.schedulers = [] then []
       else [ ("schedulers", `List (List.map sched_decl s.schedulers)) ])
    @ (if s.fishing_loots = [] then []
       else [ ("fishing_loot", `List (List.map fishing_loot s.fishing_loots)) ])
    @ (if s.block_handlers = [] then []
       else [ ("block_handlers", `List (List.map block_handler_decl s.block_handlers)) ])
    @ (if s.placement_rules = [] then []
       else [ ("placement_rules", `List (List.map placement_rule_decl s.placement_rules)) ])
  in
  [
    ("commands", `List (List.map command s.commands));
    ("events", `List (receiver_events s.receivers));
    ("functions", `List (List.map (fun f -> mark f.fn_exported (func f)) s.functions));
    ("guis", `List (List.map (fun g -> mark g.g_exported (gui g)) s.guis));
    ("scoreboards", `List (List.map (fun sb -> mark sb.sb_exported (scoreboard sb)) s.scoreboards));
    ("tablists", `List (List.map (fun tl -> mark tl.tl_exported (tablist tl)) s.tablists));
    ("bossbars", `List (List.map (fun bb -> mark bb.bb_exported (bossbar bb)) s.bossbars));
    ("server", opt server (match s.servers with [] -> None | sv :: _ -> Some sv));
  ]
  @ persistence @ content

let script (s : Ast.script) : Yojson.Safe.t =
  `Assoc
    ([ ("format", `String "swoftlang-ast"); ("version", `Int 2) ]
    @ script_fields ~modular:false s)

let module_var (mv : module_var) =
  `Assoc (with_pos mv.mv_pos [ ("name", `String mv.mv_name); ("value", expr mv.mv_value) ])

(* One entry of the bundle's "modules" array: identity keys, module-level
   vars (additive), then the same per-file content keys as the flat shape *)
let module_json ~name ~path ~entry (s : Ast.script) : Yojson.Safe.t =
  `Assoc
    ([ ("name", `String name); ("path", `String path); ("entry", `Bool entry) ]
    @ (if s.module_vars = [] then []
       else [ ("module_vars", `List (List.map module_var s.module_vars)) ])
    @ script_fields ~modular:true s)

(* Multi-module bundle (design 6A): single-file compilations without imports
   never reach this — they emit the flat shape above *)
let bundle (modules : (string * string * bool * Ast.script) list) : Yojson.Safe.t =
  `Assoc
    [
      ("format", `String "swoftlang-ast");
      ("version", `Int 2);
      ( "modules",
        `List (List.map (fun (name, path, entry, s) -> module_json ~name ~path ~entry s) modules)
      );
    ]
