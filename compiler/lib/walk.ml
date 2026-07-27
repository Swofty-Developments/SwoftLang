(* A generic, EXHAUSTIVE AST walker. Every construct that can host an expression
   or a nested statement is matched by name — there is no catch-all — so a future
   statement form fails to compile here until it is walked, rather than being
   silently skipped by an analysis that depends on total coverage (named-schedule
   collection, the v1.10.0 §5 change-handler write graph).

   [on_expr] runs on every expression and [on_stmt] on every statement, BEFORE
   recursing into that node's children. *)

open Ast

let walk ~on_expr ~on_stmt =
  let rec we (e : Ast.expr) =
    on_expr e;
    match e.e with
    | ESchedule { sc_body; _ } -> List.iter ws sc_body
    | ELambda { lam_body; _ } -> List.iter ws lam_body
    | EBinary (_, a, b) ->
      we a;
      we b
    | EUnary (_, a) -> we a
    | ECall (_, args) -> List.iter we args
    | EMethod (recv, _, args) ->
      we recv;
      List.iter we args
    | EList items -> List.iter we items
    | EProp (t, _) -> we t
    | ETaskRunning { tr_owner; _ } -> we tr_owner
    | EPersistGet (_, s) -> Option.iter we s
    | EMap fields -> List.iter (fun (_, v) -> we v) fields
    | EMapLit entries -> List.iter (fun (_, v) -> we v) entries
    | EStructNew (_, fields) -> List.iter (fun (_, v) -> we v) fields
    | EFutureSpawn (_, args) -> List.iter we args
    | EAsyncExpr { ae_body; ae_trailing } ->
      List.iter ws ae_body;
      Option.iter we ae_trailing
    | EAwait future -> we future
    | EAllOf futures | EAnyOf futures -> we futures
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
    on_stmt s;
    match s.s with
    (* --- statement-bearing forms: recurse into nested statements --- *)
    | SIf (c, t, e) ->
      we c;
      ws t;
      Option.iter ws e
    | SBlock ss | SAsyncBlock ss -> List.iter ws ss
    | STupleBind { tb_value; _ } -> we tb_value
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
    | SCallOriginal -> ()
    | SMethodCall (recv, _, args) ->
      we recv;
      List.iter we args
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
    (* the atomic op's own operands; its standalone desugaring is built from the
       SAME expressions, so walking the surface reaches everything exactly once *)
    | SPersistAtomic pa ->
      Option.iter we pa.pa_subject;
      Option.iter we pa.pa_key;
      we pa.pa_value
    | SGiveItem { gi_id; gi_target; gi_amount } ->
      we gi_id;
      we gi_target;
      Option.iter we gi_amount
    | SSpawnMob { sm_target; sm_at; _ } ->
      (match sm_target with MSById e -> we e | MSByType _ -> ());
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
    | SShowEntity { she_entity; she_target } ->
      we she_entity;
      we she_target
    | SHideEntity { hie_entity; hie_target } ->
      we hie_entity;
      we hie_target
    | SSetEntityName { sen_entity; sen_value; sen_viewer } ->
      we sen_entity;
      we sen_value;
      we sen_viewer
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
    | SShowNpc (_, e) | SHideNpc (_, e) -> we e
    | SSetHologramLine { shl_index; shl_value; _ } ->
      we shl_index;
      we shl_value
    | SSetNpcSkin { sns_skin; _ } -> wnpcsk sns_skin
    | SSetNpcName { snn_value; _ } -> we snn_value
    | SSetNpcLocation { snl_value; _ } -> we snl_value
    (* --- W-pvp: attribute modifiers + combat effect verbs --- *)
    | SAddModifier { am_id; am_entity; am_amount; _ } ->
      we am_id;
      we am_entity;
      we am_amount
    | SRemoveModifier { rm_id; rm_entity; _ } ->
      we rm_id;
      we rm_entity
    | SDamage { dm_target; dm_amount; dm_type; dm_source } ->
      we dm_target;
      we dm_amount;
      Option.iter we dm_type;
      Option.iter we dm_source
    | SKnock { kn_target; kn_from; kn_strength } ->
      we kn_target;
      we kn_from;
      Option.iter we kn_strength
    | SApplyEffect { ae_effect; ae_amplifier; ae_entity; ae_duration } ->
      we ae_effect;
      we ae_amplifier;
      we ae_entity;
      we ae_duration
    | SRemoveEffect { re_effect; re_entity } ->
      we re_effect;
      we re_entity
    | SShoot { sh_type; sh_from; sh_velocity; sh_shooter } ->
      we sh_type;
      we sh_from;
      Option.iter we sh_velocity;
      Option.iter we sh_shooter
    | STaskSet { tk_owner; tk_value; _ } ->
      we tk_owner;
      we tk_value
    | STaskCancel { tc_owner; _ } -> we tc_owner
    | SPlaceBlock { pb_block; pb_at } ->
      we pb_block;
      we pb_at
    | SRemoveBlock loc -> we loc
    (* --- v1.9.0 AI navigator statements --- *)
    | SPath { pa_mob; pa_to; pa_speed } ->
      we pa_mob;
      we pa_to;
      Option.iter we pa_speed
    | SStopPathing e -> we e
    | SLookAt e -> we e
    (* --- expression-free statements --- *)
    | SHalt | SCancelEvent | SBlank | SCancelPacket | SStop | SRemoveHologram _ | SRemoveNpc _ ->
      ()
  in
  (we, ws)

let iter_expr ~on_expr ~on_stmt e =
  let we, _ = walk ~on_expr ~on_stmt in
  we e

let iter_stmts ~on_expr ~on_stmt ss =
  let _, ws = walk ~on_expr ~on_stmt in
  List.iter ws ss

(* every statement- and expression-bearing body a script can host, in one pass *)
let iter_script ~on_expr ~on_stmt (script : Ast.script) =
  let we, ws = walk ~on_expr ~on_stmt in
  let body = function Some (ss : stmt list) -> List.iter ws ss | None -> () in
  let exec = function Some (ex : exec_block) -> List.iter ws ex.ex_stmts | None -> () in
  List.iter (fun (sd : sched_decl) -> List.iter ws sd.sd_body) script.schedulers;
  List.iter (fun (f : func) -> List.iter ws f.body) script.functions;
  List.iter (fun (c : command) -> exec c.execute) script.commands;
  List.iter (fun (mv : module_var) -> we mv.mv_value) script.module_vars;
  (* v1.10.0 §4: a persistent's default expression and its change-handler body *)
  List.iter
    (fun (pd : persistent_decl) ->
      we pd.pd_default;
      match pd.pd_change with Some pc -> List.iter ws pc.pc_body | None -> ())
    script.persistents;
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
  (* v1.9.0 AI: goal lifecycle + target selection bodies can host named schedules *)
  let scan_goal_life (gl : goal_lifecycle) =
    Option.iter we gl.gl_should_start;
    body gl.gl_on_start;
    body gl.gl_on_tick;
    Option.iter we gl.gl_should_end;
    body gl.gl_on_end
  in
  let scan_ai_block (aib : ai_block) =
    List.iter
      (function ATBlock { at_body; _ } -> List.iter ws at_body | ATNatural { at_range; _ } -> we at_range)
      aib.aib_targets;
    List.iter (fun (g : ai_goal) -> scan_goal_life g.ag_life) aib.aib_goals
  in
  List.iter (fun (gt : goal_type_decl) -> scan_goal_life gt.gt_life) script.goal_types;
  List.iter
    (fun (mb : mob_decl) ->
      body mb.mb_on_spawn;
      body mb.mb_on_death;
      body mb.mb_on_attack;
      body mb.mb_on_hit;
      Option.iter scan_ai_block mb.mb_ai_block;
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
      body n.n_on_click;
      body n.n_on_left_click;
      scan_handlers n.n_handlers)
    script.npcs;
  List.iter
    (fun (bh : block_handler_decl) ->
      List.iter (fun (cb : block_cb) -> List.iter ws cb.cb_body) bh.bh_callbacks)
    script.block_handlers;
  List.iter
    (fun (pr : placement_rule_decl) ->
      List.iter (fun (cb : block_cb) -> List.iter ws cb.cb_body) pr.pr_callbacks)
    script.placement_rules;
  List.iter (fun (r : receiver_decl) -> scan_handlers r.rc_methods) script.receivers
