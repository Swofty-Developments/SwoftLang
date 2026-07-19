open Ast
open Registry
open Tc_types
open Tc_env
open Tc_decl

(* One module of a compilation unit, in dependency order (imports first).
   tm_imports are direct imports only — no re-export in v1. *)
type module_input = {
  tm_name : string;
  tm_file : string;
  tm_imports : string list;
  tm_script : Ast.script;
}

let make_ctx file =
  {
    file;
    errors = [];
    quiet = false;
    funcs = Hashtbl.create 16;
    persists = Hashtbl.create 16;
    item_ids = Hashtbl.create 16;
    mob_ids = Hashtbl.create 16;
    scoreboards = Hashtbl.create 8;
    tablists = Hashtbl.create 8;
    bossbars = Hashtbl.create 8;
    holograms = Hashtbl.create 8;
    npcs = Hashtbl.create 8;
    guis = Hashtbl.create 8;
    schedules = Hashtbl.create 8;
    mod_vars = Hashtbl.create 8;
    import_privates = Hashtbl.create 8;
  }

(* Collect every named-schedule name declared in a script: top-level
   'every ... as "name"' plus inline 'schedule ... as "name"' expressions
   anywhere in a handler/function/initializer body. These feed the string-form
   'cancel schedule "name"' / is_running("name") reference checks; missing one
   would false-positive a valid program, so the walk covers every body that can
   host statements. *)
let collect_sched_names (script : Ast.script) : string list =
  let names = ref [] in
  let add = function Some n -> names := n :: !names | None -> () in
  let rec we (e : Ast.expr) =
    match e.e with
    | ESchedule { sc_name; sc_body; _ } ->
      add sc_name;
      List.iter ws sc_body
    | ELambda { lam_body; _ } -> List.iter ws lam_body
    | EBinary (_, a, b) ->
      we a;
      we b
    | EUnary (_, a) -> we a
    | ECall (_, args) -> List.iter we args
    | EList items -> List.iter we items
    | EProp (t, _) -> we t
    | EPersistGet (_, s) -> Option.iter we s
    | EMap fields -> List.iter (fun (_, v) -> we v) fields
    | EMapLit entries -> List.iter (fun (_, v) -> we v) entries
    | EString _ | ENumber _ | EBool _ | ENone | EVar _ | EType _ | EAllPlayers
    | ELoaderStorage _ ->
      ()
  and wsk (sk : Ast.skin) =
    match sk with
    | SkBuiltin _ -> ()
    | SkPlayer p -> we p
    | SkCustom (a, b) ->
      we a;
      we b
  and wnpcsk (sk : Ast.npc_skin) =
    match sk with
    | NpcSkinUsername e -> we e
    | NpcSkinTexture (a, b) ->
      we a;
      we b
  and wgo (go : Ast.gui_open) =
    we go.go_target;
    List.iter (fun (_, v) -> we v) go.go_init
  (* Exhaustive over every statement form: no catch-all, so a future statement
     that can host an expression (and thus a named ESchedule) fails to compile
     here until it is walked, rather than silently dropping its schedule name. *)
  and ws (s : Ast.stmt) =
    match s.s with
    (* --- statement-bearing forms: recurse into nested statements --- *)
    | SIf (c, t, e) ->
      we c;
      ws t;
      Option.iter ws e
    | SBlock ss | SAsyncBlock ss -> List.iter ws ss
    | SLoop (c, _, b) ->
      we c;
      ws b
    | SWhile (c, b) ->
      we c;
      ws b
    | SForeach { fe_iter; fe_limit; fe_body; _ } ->
      we fe_iter;
      Option.iter we fe_limit;
      ws fe_body
    | SForeachMap { fm_map; fm_body; _ } ->
      we fm_map;
      ws fm_body
    | SRepeat { rp_count; rp_body; _ } ->
      we rp_count;
      List.iter ws rp_body
    (* --- leaf statements: walk every expression child so a named ESchedule
       nested in any of them still lands in the name set --- *)
    | SSend (a, b) ->
      we a;
      Option.iter we b
    | SBroadcast e -> we e
    | STeleport (a, b) ->
      we a;
      we b
    | SAssign (_, v) -> we v
    | SSetProp (t, _, v) ->
      we t;
      we v
    | SCall (_, args) | SSpawn (_, args) -> List.iter we args
    | SReturn v -> Option.iter we v
    | SWait (e, _) -> we e
    | SOpenGui go | SReplaceGui go -> wgo go
    | SCloseGui e | SGuiBack e -> we e
    | SShowScoreboard (_, e) -> we e
    | SHideScoreboard e | SUpdateScoreboard e -> we e
    | SShowTablist (_, e) -> we e
    | SHideTablist e -> we e
    | SSetTablistPart (_, a, b) ->
      we a;
      we b
    | STitle { t_title; t_subtitle; t_target; _ } ->
      we t_title;
      Option.iter we t_subtitle;
      we t_target
    | SClearTitle e -> we e
    | SActionbar { ab_text; ab_target; _ } ->
      we ab_text;
      we ab_target
    | SShowBossbar (_, e) | SHideBossbar (_, e) -> we e
    | SSetBossbarPart { bp_value; bp_target; _ } ->
      we bp_value;
      we bp_target
    | SBelowname (a, b) | SSetBelownameScore (a, b) ->
      we a;
      we b
    | SClearBelowname e -> we e
    | SLine e -> we e
    | SEntry (e, sk) ->
      we e;
      wsk sk
    | SFill sk -> wsk sk
    | SPersistSet (_, subj, v) ->
      Option.iter we subj;
      we v
    | SGiveItem { gi_id; gi_target; gi_amount } ->
      we gi_id;
      we gi_target;
      Option.iter we gi_amount
    | SSpawnMob { sm_id; sm_at; _ } ->
      we sm_id;
      we sm_at
    | SDespawnMob e -> we e
    | SSetNametag { nt_target; nt_value; nt_viewer; _ } ->
      we nt_target;
      we nt_value;
      Option.iter we nt_viewer
    | SResetNametag { rn_target; rn_viewer } ->
      we rn_target;
      Option.iter we rn_viewer
    | SSendPacket { sp_fields; sp_target; _ } ->
      List.iter (fun (_, v) -> we v) sp_fields;
      we sp_target
    | SShowDisplay { sh_display; sh_target } ->
      we sh_display;
      we sh_target
    | SHideDisplay { hi_display; hi_target } ->
      we hi_display;
      we hi_target
    | SMountDisplay { mo_display; mo_entity } ->
      we mo_display;
      we mo_entity
    | STeleportDisplay { tp_display; tp_to } ->
      we tp_display;
      we tp_to
    | SDestroyDisplay e -> we e
    | SReply { rp_code; rp_body } ->
      Option.iter we rp_code;
      we rp_body
    | SPlaySong { ps_song; ps_target; ps_tick; ps_at; ps_radius } ->
      we ps_song;
      Option.iter we ps_target;
      Option.iter we ps_tick;
      Option.iter we ps_at;
      Option.iter we ps_radius
    | SPauseSong e | SResumeSong e | SStopSong e | SBroadcastSong e -> we e
    | SSongVolume { vo_target; vo_volume } ->
      we vo_target;
      we vo_volume
    | SFadeSong { fa_target; fa_volume; _ } ->
      we fa_target;
      we fa_volume
    | SSetBlock { bl_at; bl_block } ->
      we bl_at;
      we bl_block
    | SFillBlocks { fb_from; fb_to; fb_block } ->
      we fb_from;
      we fb_to;
      we fb_block
    | SPlaySound { sn_sound; sn_target; sn_at; sn_volume; sn_pitch } ->
      we sn_sound;
      we sn_target;
      Option.iter we sn_at;
      Option.iter we sn_volume;
      Option.iter we sn_pitch
    | SStopSound { so_sound; so_target } ->
      Option.iter we so_sound;
      we so_target
    | SSpawnParticle { pa_particle; pa_at; pa_count; pa_offset; pa_speed; pa_viewer } ->
      we pa_particle;
      we pa_at;
      Option.iter we pa_count;
      Option.iter
        (fun (x, y, z) ->
          we x;
          we y;
          we z)
        pa_offset;
      Option.iter we pa_speed;
      Option.iter we pa_viewer
    | SSetServerMotd e -> we e
    | SShowToast { to_title; to_description; to_icon; to_target; _ } ->
      we to_title;
      Option.iter we to_description;
      Option.iter we to_icon;
      we to_target
    | SDrawPixel { px_canvas; px_x; px_y; px_color } ->
      we px_canvas;
      we px_x;
      we px_y;
      we px_color
    | SDrawRect { rc_canvas; rc_x1; rc_y1; rc_x2; rc_y2; rc_color } ->
      we rc_canvas;
      we rc_x1;
      we rc_y1;
      we rc_x2;
      we rc_y2;
      we rc_color
    | SDrawText { tx_canvas; tx_x; tx_y; tx_text; tx_color } ->
      we tx_canvas;
      we tx_x;
      we tx_y;
      we tx_text;
      we tx_color
    | SGiveMap { gm_canvas; gm_target } ->
      we gm_canvas;
      we gm_target
    | SCancelSchedule e -> we e
    | SCreateWorld { cw_name; cw_loader; _ } ->
      we cw_name;
      we cw_loader
    | SLoadWorld { lw_name; lw_loader } ->
      we lw_name;
      we lw_loader
    | SUnloadWorld { uw_name; uw_teleport; _ } ->
      we uw_name;
      Option.iter we uw_teleport
    | SSaveWorld e -> we e
    | SCloneWorld { cl_from; cl_to; cl_loader } ->
      we cl_from;
      we cl_to;
      we cl_loader
    | SDeleteWorld { dw_name; dw_loader } ->
      we dw_name;
      we dw_loader
    | SImportWorld { iw_path; iw_name; iw_loader } ->
      we iw_path;
      we iw_name;
      we iw_loader
    | SSpawnEntity { se_type; se_at; _ } ->
      we se_type;
      we se_at
    | SRemoveEntity e -> we e
    | SMount { m_rider; m_vehicle } ->
      we m_rider;
      we m_vehicle
    | SDismount e -> we e
    | SLaunchProjectile { lp_type; lp_from; lp_velocity; lp_speed; _ } ->
      we lp_type;
      we lp_from;
      Option.iter we lp_velocity;
      Option.iter we lp_speed
    | SDispenseFrom e -> we e
    | SShowHologram (_, e) | SHideHologram (_, e) | SMoveHologram (_, e) -> we e
    | SSetHologramLine { shl_index; shl_value; _ } ->
      we shl_index;
      we shl_value
    | SSetNpcSkin { sns_skin; _ } -> wnpcsk sns_skin
    | SSetNpcName { snn_value; _ } -> we snn_value
    | SSetNpcLocation { snl_value; _ } -> we snl_value
    (* --- expression-free statements --- *)
    | SHalt | SCancelEvent | SBlank | SCancelPacket | SStop | SRemoveHologram _ | SRemoveNpc _ ->
      ()
  in
  let body = function Some (ss : stmt list) -> List.iter ws ss | None -> () in
  let exec = function Some (ex : exec_block) -> List.iter ws ex.ex_stmts | None -> () in
  List.iter
    (fun (sd : sched_decl) ->
      add sd.sd_name;
      List.iter ws sd.sd_body)
    script.schedulers;
  List.iter (fun (f : func) -> List.iter ws f.body) script.functions;
  List.iter (fun (c : command) -> exec c.execute) script.commands;
  List.iter (fun (ev : event) -> exec ev.ev_execute) script.events;
  List.iter (fun (mv : module_var) -> we mv.mv_value) script.module_vars;
  List.iter (fun (pk : packet_listener) -> exec pk.pk_execute) script.packet_listeners;
  List.iter (fun (a : api_decl) -> exec a.api_execute) script.apis;
  List.iter (fun (sb : scoreboard) -> List.iter ws sb.sb_lines) script.scoreboards;
  List.iter
    (fun (tl : tablist) -> List.iter (fun col -> List.iter ws col.col_body) tl.tl_columns)
    script.tablists;
  List.iter
    (fun (g : gui) ->
      body g.g_on_open;
      body g.g_on_close;
      body g.g_on_click;
      List.iter
        (fun (sl : gui_slot) -> List.iter (fun ch -> List.iter ws ch.ch_body) sl.gs_clicks)
        g.g_slots;
      List.iter (fun (ed : gui_editable) -> body ed.ge_on_change) g.g_editable;
      match g.g_paginate with Some pg -> body pg.gp_on_click | None -> ())
    script.guis;
  let scan_handlers hs = List.iter (fun (h : inline_handler) -> List.iter ws h.ih_body) hs in
  List.iter
    (fun (mb : mob_decl) ->
      body mb.mb_on_spawn;
      body mb.mb_on_death;
      body mb.mb_on_attack;
      (match mb.mb_on_hit with Some (_, ss) -> List.iter ws ss | None -> ());
      scan_handlers mb.mb_handlers)
    script.mobs;
  List.iter
    (fun (it : item_decl) ->
      body it.it_lore;
      List.iter (fun ch -> List.iter ws ch.ch_body) it.it_on_click;
      scan_handlers it.it_handlers)
    script.items;
  List.iter
    (fun (h : hologram) ->
      List.iter ws h.h_lines;
      scan_handlers h.h_handlers)
    script.holograms;
  List.iter
    (fun (n : npc) ->
      (match n.n_on_click with Some (_, ss) -> List.iter ws ss | None -> ());
      (match n.n_on_left_click with Some (_, ss) -> List.iter ws ss | None -> ());
      scan_handlers n.n_handlers)
    script.npcs;
  !names

(* UI + scheduler declaration names are unit-global (unique across the
   compilation unit, landing in one runtime registry), so every module's
   checker resolves references against the whole unit's names. *)
let register_unit_names ctx (scripts : Ast.script list) =
  List.iter
    (fun (s : Ast.script) ->
      List.iter (fun (sb : scoreboard) -> Hashtbl.replace ctx.scoreboards sb.sb_name ()) s.scoreboards;
      List.iter (fun (tl : tablist) -> Hashtbl.replace ctx.tablists tl.tl_name ()) s.tablists;
      List.iter (fun (bb : bossbar) -> Hashtbl.replace ctx.bossbars bb.bb_name ()) s.bossbars;
      List.iter (fun (h : hologram) -> Hashtbl.replace ctx.holograms h.h_name ()) s.holograms;
      List.iter (fun (n : npc) -> Hashtbl.replace ctx.npcs n.n_name ()) s.npcs;
      List.iter (fun (g : gui) -> Hashtbl.replace ctx.guis g.g_name ()) s.guis;
      List.iter (fun n -> Hashtbl.replace ctx.schedules n ()) (collect_sched_names s))
    scripts

type mod_state = {
  ms_input : module_input;
  ms_ctx : ctx;
  (* own function signatures; instances are shared with importers so return
     types and coloring refined during this module's check flow across
     module boundaries *)
  ms_exported_fns : (string * pos) list;
}

let register_functions ctx (script : Ast.script) =
  List.iter
    (fun f ->
      if Hashtbl.mem ctx.funcs f.fn_name then
        err ctx f.fn_pos "duplicate function '%s'" f.fn_name
      else begin
        (* the runtime resolves user functions before builtins for EVERY
           script in the process, so a function named after a builtin would
           hijack the builtin even for scripts that never imported it —
           reject the collision like module vars and persistents do *)
        if find_builtin f.fn_name <> None then
          err ctx f.fn_pos "function '%s' collides with the builtin function '%s' — rename it"
            f.fn_name f.fn_name;
        Hashtbl.add ctx.funcs f.fn_name
          {
            f_async = f.fn_async;
            f_params =
              List.map
                (fun (p : Ast.param) ->
                  (p.p_name, match p.p_type with Some dt -> ty_of_dt dt | None -> TAny))
                f.params;
            f_ret = TAny;
          }
      end)
    script.functions

(* Module-var initializers evaluate in declaration order, so direct
   references only see earlier vars — but a call to one of the module's own
   functions escapes that ordering: function bodies are checked against ALL
   module vars and can read ones that are not initialized yet (a statically
   Integer var would observe none at load). Reject direct calls to
   this-module functions in initializer position; lambda and schedule bodies
   are deferred and run after initialization, so they stay allowed. *)
let check_initializer_calls ctx own_fns (mv : module_var) =
  let rec walk (e : Ast.expr) =
    match e.e with
    | ECall (name, args) ->
      if Hashtbl.mem own_fns name then
        err ctx e.epos
          "module variable '%s' calls the function '%s' in its initializer — functions can \
           read module variables that are not initialized yet at this point; inline the value \
           or reorder the declarations"
          mv.mv_name name;
      List.iter walk args
    | EBinary (_, a, b) ->
      walk a;
      walk b
    | EUnary (_, a) -> walk a
    | EList items -> List.iter walk items
    | EProp (target, _) -> walk target
    | EPersistGet (_, subject) -> Option.iter walk subject
    | EMap fields -> List.iter (fun (_, v) -> walk v) fields
    | EMapLit entries -> List.iter (fun (_, v) -> walk v) entries
    | ELambda _ | ESchedule _ -> () (* deferred bodies run after initialization *)
    | EString _ | ENumber _ | EBool _ | ENone | EVar _ | EType _ | EAllPlayers
    | ELoaderStorage _ ->
      ()
  in
  walk mv.mv_value

(* Module-level 'var name = expr' declarations: typed by inference from the
   initializer (checked in declaration order, so later initializers see
   earlier vars), private to the module, non-persistent. *)
let check_module_vars ctx (script : Ast.script) =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false } in
  let own_fns = Hashtbl.create 8 in
  List.iter (fun f -> Hashtbl.replace own_fns f.fn_name ()) script.functions;
  List.iter
    (fun (mv : module_var) ->
      if Hashtbl.mem ctx.mod_vars mv.mv_name then
        err ctx mv.mv_pos "duplicate module variable '%s'" mv.mv_name
      else begin
        check_persist_shadow ctx mv.mv_pos "module variable" mv.mv_name;
        if Hashtbl.mem ctx.funcs mv.mv_name then
          err ctx mv.mv_pos "module variable '%s' collides with the function '%s'" mv.mv_name
            mv.mv_name;
        if find_builtin mv.mv_name <> None then
          err ctx mv.mv_pos "module variable '%s' collides with the builtin function '%s'"
            mv.mv_name mv.mv_name;
        if List.mem mv.mv_name [ "sender"; "event"; "args" ] then
          err ctx mv.mv_pos
            "module variable '%s' collides with the built-in '%s' binding — pick another name"
            mv.mv_name mv.mv_name;
        check_initializer_calls ctx own_fns mv;
        let env = base_env ctx in
        let ty = Tc_expr.type_of ctx bctx env mv.mv_value in
        require_present ctx env mv.mv_value ty ~use:"the module variable's initial value";
        Hashtbl.replace ctx.mod_vars mv.mv_name ty
      end)
    script.module_vars

let check_module_body ctx (script : Ast.script) =
  List.iter (check_persistent ctx) script.persistents;
  check_storages ctx script.storages;
  List.iter (check_function ctx) script.functions;
  List.iter (check_command ctx) script.commands;
  List.iter (check_event ctx) script.events;
  List.iter (check_gui ctx) script.guis;
  List.iter (check_scoreboard ctx) script.scoreboards;
  List.iter (check_tablist ctx) script.tablists;
  List.iter (check_bossbar ctx) script.bossbars;
  check_holograms ctx script.holograms;
  check_npcs ctx script.npcs;
  List.iter (check_item_decl ctx) script.items;
  List.iter (check_mob_decl ctx) script.mobs;
  List.iter (check_packet_listener ctx) script.packet_listeners;
  List.iter (check_api_decl ctx) script.apis;
  List.iter (check_sched_decl ctx) script.schedulers;
  check_fishing_loots ctx script.fishing_loots;
  check_servers ctx script.servers

let dedupe errors =
  let seen = Hashtbl.create 16 in
  List.filter
    (fun (e : Diagnostics.error) ->
      let key = (e.file, e.line, e.col, e.msg) in
      if Hashtbl.mem seen key then false
      else begin
        Hashtbl.add seen key ();
        true
      end)
    errors

let run_all (modules : module_input list) : Diagnostics.error list =
  (* --- pass 1: per-module signatures --- *)
  let states =
    List.map
      (fun tm ->
        let ctx = make_ctx tm.tm_file in
        register_functions ctx tm.tm_script;
        List.iter (register_persistent ctx) tm.tm_script.persistents;
        register_items ctx tm.tm_script.items;
        register_mobs ctx tm.tm_script.mobs;
        let exported =
          List.filter_map
            (fun f -> if f.fn_exported then Some (f.fn_name, f.fn_pos) else None)
            tm.tm_script.functions
        in
        { ms_input = tm; ms_ctx = ctx; ms_exported_fns = exported })
      modules
  in
  let by_name = Hashtbl.create 8 in
  List.iter (fun ms -> Hashtbl.replace by_name ms.ms_input.tm_name ms) states;

  (* UI + scheduler names are unit-global, so give every module's checker the
     whole unit's declared names for reference validation *)
  let all_scripts = List.map (fun ms -> ms.ms_input.tm_script) states in
  List.iter (fun ms -> register_unit_names ms.ms_ctx all_scripts) states;

  (* --- cross-module collision checks --- *)
  let where ms = Printf.sprintf "module '%s' (%s)" ms.ms_input.tm_name ms.ms_input.tm_file in
  (match states with
  | [] | [ _ ] -> () (* single module: nothing global to collide *)
  | _ ->
    (* exported function names are unique across the unit — the runtime
       merges them into one registry *)
    let fn_owner = Hashtbl.create 16 in
    List.iter
      (fun ms ->
        List.iter
          (fun (name, pos) ->
            match Hashtbl.find_opt fn_owner name with
            | Some other ->
              err ms.ms_ctx pos "function '%s' is exported by both %s and %s" name
                (where other) (where ms)
            | None -> Hashtbl.replace fn_owner name ms)
          ms.ms_exported_fns)
      states;
    (* item/mob/gui/scoreboard/tablist/bossbar identifiers land in global
       runtime registries, so they must be unique across the unit whether
       exported or not; persistent names key one shared storage slot at
       runtime, so a cross-module duplicate would silently share (and
       type-confuse) state between supposedly-private modules *)
    let id_owner = Hashtbl.create 16 in
    let claim ms kind id pos =
      let key = kind ^ ":" ^ id in
      match Hashtbl.find_opt id_owner key with
      | Some other ->
        err ms.ms_ctx pos "%s \"%s\" is declared in both %s and %s" kind id (where other)
          (where ms)
      | None -> Hashtbl.replace id_owner key ms
    in
    List.iter
      (fun ms ->
        let s = ms.ms_input.tm_script in
        List.iter (fun it -> claim ms "item" it.it_id it.it_pos) s.items;
        List.iter (fun mb -> claim ms "mob" mb.mb_id mb.mb_pos) s.mobs;
        List.iter (fun g -> claim ms "gui" g.g_name g.g_pos) s.guis;
        List.iter (fun sb -> claim ms "scoreboard" sb.sb_name sb.sb_pos) s.scoreboards;
        List.iter (fun tl -> claim ms "tablist" tl.tl_name tl.tl_pos) s.tablists;
        List.iter (fun bb -> claim ms "bossbar" bb.bb_name bb.bb_pos) s.bossbars;
        List.iter (fun h -> claim ms "hologram" h.h_name h.h_pos) s.holograms;
        List.iter (fun n -> claim ms "npc" n.n_name n.n_pos) s.npcs;
        List.iter
          (fun (fl : fishing_loot) -> claim ms "fishing_loot" fl.fl_name fl.fl_pos)
          s.fishing_loots;
        List.iter
          (fun (pd : persistent_decl) -> claim ms "persistent" pd.pd_name pd.pd_pos)
          s.persistents)
      states);

  (* --- import injection + import-shadow collisions --- *)
  List.iter
    (fun ms ->
      let ctx = ms.ms_ctx in
      List.iter
        (fun imported_name ->
          match Hashtbl.find_opt by_name imported_name with
          | None -> () (* unresolved imports are caught by the module loader *)
          | Some dep ->
            List.iter
              (fun (fname, _) ->
                if Hashtbl.mem ctx.funcs fname then begin
                  (* a local declaration would silently shadow the import *)
                  match
                    List.find_opt (fun f -> f.fn_name = fname) ms.ms_input.tm_script.functions
                  with
                  | Some f ->
                    err ctx f.fn_pos
                      "function '%s' collides with the function of the same name imported \
                       from %s — rename one of them"
                      fname (where dep)
                  | None -> ()
                end
                else Hashtbl.add ctx.funcs fname (Hashtbl.find dep.ms_ctx.funcs fname))
              dep.ms_exported_fns;
            (* remember the import's private functions for precise errors *)
            List.iter
              (fun f ->
                if not f.fn_exported then
                  Hashtbl.replace ctx.import_privates f.fn_name (where dep))
              dep.ms_input.tm_script.functions;
            (* exported content ids become visible for literal give/spawn/
               drops references in the importer *)
            List.iter
              (fun it ->
                if it.it_exported && not (Hashtbl.mem ctx.item_ids it.it_id) then
                  Hashtbl.add ctx.item_ids it.it_id ())
              dep.ms_input.tm_script.items;
            List.iter
              (fun mb ->
                if mb.mb_exported && not (Hashtbl.mem ctx.mob_ids mb.mb_id) then
                  Hashtbl.add ctx.mob_ids mb.mb_id ())
              dep.ms_input.tm_script.mobs)
        ms.ms_input.tm_imports)
    states;

  (* --- pass 2: per-module checks in dependency order, so imported return
     types are refined before their callers are checked --- *)
  List.iter
    (fun ms ->
      check_module_vars ms.ms_ctx ms.ms_input.tm_script;
      check_module_body ms.ms_ctx ms.ms_input.tm_script)
    states;

  dedupe (List.concat_map (fun ms -> List.rev ms.ms_ctx.errors) states)

let run ~file (script : Ast.script) : Diagnostics.error list =
  run_all
    [ { tm_name = "main"; tm_file = file; tm_imports = []; tm_script = script } ]
