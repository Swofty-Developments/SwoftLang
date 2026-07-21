open Ast
open Registry
open Tc_types
open Tc_env
open Tc_expr
open Tc_registry_checks

(* the bare 'all' keyword parses to the string literal "all" (the broadcast
   spelling, resolved runtime-side to every online player), so a String target
   is only legal when it is literally that keyword — never an arbitrary String
   value (a player name String is NOT a target: the runtime rejects it). *)
let is_all_keyword e = match e.e with EString "all" -> true | _ -> false

(* a viewer/recipient target must resolve to a Player, a list of players, or
   the 'all' broadcast keyword — not a String/Location/other scalar *)
let target_ok e t =
  match t with
  | TPlayer | TAny | TList _ -> true
  | TString -> is_all_keyword e
  | _ -> false

let rec check_stmt ctx bctx env st : env * bool =
  match st.s with
  | SSend (msg, target) ->
    let mt = type_of ctx bctx env msg in
    require_present ctx env msg mt ~use:"the message";
    (match target with
    | Some t ->
      let tt = type_of ctx bctx env t in
      require_present ctx env t tt ~use:"the send target";
      if not (target_ok t tt) then
        err ctx t.epos "cannot send a message to a %s; expected a Player, a list of players, or 'all'"
          (ty_to_string tt)
    | None -> ());
    (env, false)
  | SBroadcast msg ->
    let mt = type_of ctx bctx env msg in
    require_present ctx env msg mt ~use:"the message";
    (env, false)
  | STeleport (ent, tgt) ->
    let et = type_of ctx bctx env ent in
    require_present ctx env ent et ~use:"the teleported entity";
    (match et with
    | TPlayer | TAny -> ()
    | TEither _ ->
      err ctx ent.epos "can only teleport players; narrow %s first with 'is a'"
        (ty_to_string et)
    | _ -> err ctx ent.epos "can only teleport players (got %s)" (ty_to_string et));
    let tt = type_of ctx bctx env tgt in
    require_present ctx env tgt tt ~use:"the teleport target";
    (match tt with
    | TPlayer | TLocation | TAny -> ()
    | TEither ts when List.for_all (fun t -> t = TPlayer || t = TLocation || t = TAny) ts -> ()
    | _ ->
      err ctx tgt.epos "teleport target must be a Player or Location (got %s)" (ty_to_string tt));
    (env, false)
  | SHalt -> (env, true)
  | SStop ->
    if not bctx.in_schedule then
      err ctx st.spos
        "'stop' is only allowed inside an 'every', 'schedule', or 'repeat' body (it cancels the \
         enclosing schedule); use 'halt' to end the current task";
    (* stop cancels the repetition but the current run finishes, so control
       flow continues past it (unlike 'halt') *)
    (env, false)
  | SRepeat { rp_count; rp_every; rp_body } ->
    let ct = type_of ctx bctx env rp_count in
    require_present ctx env rp_count ct ~use:"the repeat count";
    (match ct with
    | TInteger | TAny -> ()
    | _ ->
      err ctx rp_count.epos "repeat count must be a positive Integer (got %s)" (ty_to_string ct));
    (match rp_every with
    | Some n when n <= 0 -> err ctx st.spos "repeat cadence must be positive"
    | _ -> ());
    (* the body runs on the scheduler: async-colored, 'stop' legal, 'run'
       (1-based, capped at the count) in scope *)
    let bctx' = { bctx with color = Async; ret_sink = None; in_schedule = true; override = None } in
    let benv = bind { env with facts = SM.empty } "run" TInteger in
    ignore (check_stmts ctx bctx' benv rp_body);
    (env, false)
  | SCancelEvent ->
    (match bctx.event with
    | None -> err ctx st.spos "'cancel event' is only allowed inside an event handler"
    | Some ev when not ev.e_cancellable ->
      err ctx st.spos "event '%s' is not cancellable" ev.e_name
    | Some _ when bctx.color = Async ->
      err ctx st.spos "'cancel event' must run before the handler goes async"
    | Some _ -> ());
    (env, false)
  | SIf (cond, thenb, elseb) ->
    let ct = type_of ctx bctx env cond in
    require_present ctx env cond ct ~use:"the condition";
    require_boolish ctx cond ct;
    let ft, fe = cond_facts ctx bctx env cond in
    let env_t, term_t = check_stmt ctx bctx (add_facts env ft) thenb in
    let env_e, term_e =
      match elseb with
      | Some e -> check_stmt ctx bctx (add_facts env fe) e
      | None -> (add_facts env fe, false)
    in
    if term_t && term_e then (env, true)
    else if term_t then (env_e, false)
    else if term_e then (env_t, false)
    else (join_env env_t env_e, false)
  | SBlock ss -> check_stmts ctx bctx env ss
  | SAssign (x, v) ->
    let vt = type_of ctx bctx env v in
    let env = invalidate_root env x in
    ({ env with vars = SM.add x { v_ty = vt; v_maybe = false } env.vars }, false)
  | SSetProp (target, name, value) -> check_set_prop ctx bctx env st.spos target name value
  | SLoop (count, var, body) ->
    let ct = type_of ctx bctx env count in
    require_present ctx env count ct ~use:"the loop count";
    if not (num_ok ct) then
      err ctx count.epos "loop count must be a number (got %s)" (ty_to_string ct);
    (match var with
    | Some v -> check_persist_shadow ctx st.spos "loop variable" v
    | None -> ());
    let benv = match var with Some v -> bind env v TInteger | None -> env in
    let benv = widen_loop ctx bctx benv body ~facts_of:(fun _ -> []) in
    let benv', _ = check_stmt ctx bctx benv body in
    (join_env env (restore_binding env benv' var), false)
  | SWhile (cond, body) ->
    let ct = type_of ctx bctx env cond in
    require_present ctx env cond ct ~use:"the condition";
    require_boolish ctx cond ct;
    let facts_of e = fst (cond_facts ctx bctx e cond) in
    let benv = widen_loop ctx bctx env body ~facts_of in
    let benv', _ = check_stmt ctx bctx benv body in
    (join_env env benv', false)
  | SForeach { fe_var; fe_limit; fe_iter; fe_body } ->
    (match fe_limit with
    | Some l ->
      let lt = type_of ctx bctx env l in
      require_present ctx env l lt ~use:"the loop limit";
      if not (num_ok lt) then
        err ctx l.epos "loop limit must be a number (got %s)" (ty_to_string lt)
    | None -> ());
    let it = type_of ctx bctx env fe_iter in
    require_present ctx env fe_iter it ~use:"the loop iterable";
    check_persist_shadow ctx st.spos "loop variable" fe_var;
    let elem =
      match it with
      | TList t -> t
      | TAny -> TAny
      | _ ->
        err ctx fe_iter.epos "loop iterable must be a list (got %s)" (ty_to_string it);
        TAny
    in
    let benv = widen_loop ctx bctx (bind env fe_var elem) fe_body ~facts_of:(fun _ -> []) in
    let benv', _ = check_stmt ctx bctx benv fe_body in
    (join_env env (restore_binding env benv' (Some fe_var)), false)
  | SForeachMap { fm_key; fm_val; fm_map; fm_body } ->
    let mt = type_of ctx bctx env fm_map in
    require_present ctx env fm_map mt ~use:"the map to loop over";
    let kelem, velem =
      match unwrap mt with
      | TMap (k, v) -> (k, v)
      | TAny -> (TAny, TAny)
      | _ ->
        err ctx fm_map.epos "can only loop 'as key -> value' over a map (got %s)"
          (ty_to_string mt);
        (TAny, TAny)
    in
    check_persist_shadow ctx st.spos "loop key variable" fm_key;
    check_persist_shadow ctx st.spos "loop value variable" fm_val;
    if fm_key = fm_val then
      err ctx st.spos "the key and value binders of 'loop ... as key -> value' must differ";
    let benv = bind (bind env fm_key kelem) fm_val velem in
    let benv = widen_loop ctx bctx benv fm_body ~facts_of:(fun _ -> []) in
    let benv', _ = check_stmt ctx bctx benv fm_body in
    let after = restore_binding env benv' (Some fm_key) in
    let after = restore_binding env after (Some fm_val) in
    (join_env env after, false)
  | SCall (name, args) ->
    ignore (call_type ctx bctx env st.spos name args);
    (env, false)
  | SMethodCall (recv, name, args) ->
    ignore (check_method ctx bctx env st.spos recv name args ~as_stmt:true);
    (env, false)
  | SReturn v ->
    (match bctx.ret_sink with
    | Some (vals, bare) -> (
      match v with
      | Some e -> vals := type_of ctx bctx env e :: !vals
      | None -> bare := true)
    | None -> ( match v with Some e -> ignore (type_of ctx bctx env e) | None -> ()));
    (env, true)
  | SWait (amount, _) ->
    if bctx.packet && bctx.color = Sync then
      err ctx st.spos
        "'wait' is not allowed inside Packet handlers; wrap the work in an 'async { }' block"
    else if bctx.color = Sync then
      err ctx st.spos "'wait' is only allowed in async functions, 'execute async', or 'async { }' blocks";
    let at = type_of ctx bctx env amount in
    require_present ctx env amount at ~use:"the wait amount";
    if not (num_ok at) then
      err ctx amount.epos "wait amount must be a number (got %s)" (ty_to_string at);
    (env, false)
  | SSpawn (name, args) ->
    if bctx.packet && bctx.color = Sync then
      err ctx st.spos
        "'spawn' is not allowed inside Packet handlers; wrap the work in an 'async { }' \
         block";
    (* same resolution order as calls: callable variable, then declared
       function; spawn detaches, so async callees are fine in sync color *)
    (match callee_var_type env name with
    | Some (TFunction f) -> check_call_args ctx bctx env st.spos name f.fn_params args
    | Some TAny | Some (TOptional TAny) ->
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args
    | Some (TOptional (TFunction _)) ->
      err ctx st.spos "'%s' may be missing; check it with 'if %s exists' before spawning it"
        name name;
      List.iter (fun a -> ignore (type_of ctx bctx env a)) args
    | looked -> (
      match Hashtbl.find_opt ctx.funcs name with
      | Some f -> check_call_args ctx bctx env st.spos name (List.map snd f.f_params) args
      | None ->
        (match looked with
        | Some t -> not_a_function ctx st.spos name t
        | None ->
          let candidates = Hashtbl.fold (fun k _ acc -> k :: acc) ctx.funcs [] in
          err ctx st.spos "'spawn' requires a declared function; unknown function '%s'%s" name
            (suggestion name candidates));
        List.iter (fun a -> ignore (type_of ctx bctx env a)) args));
    (env, false)
  | SAsyncBlock ss ->
    (* the spawned task gets a snapshot of the variables; its writes don't leak back *)
    ignore (check_stmts ctx { bctx with color = Async } env ss);
    (env, false)
  | SOpenGui go | SReplaceGui go ->
    check_decl_name ctx st.spos "gui" ctx.guis go.go_name;
    let tt = type_of ctx bctx env go.go_target in
    require_present ctx env go.go_target tt ~use:"the gui target";
    (match tt with
    | TPlayer | TAny -> ()
    | _ ->
      err ctx go.go_target.epos "cannot open a gui to a %s; expected a Player" (ty_to_string tt));
    List.iter
      (fun (_, v) ->
        let vt = type_of ctx bctx env v in
        require_present ctx env v vt ~use:"the initial state value")
      go.go_init;
    (env, false)
  | SCloseGui t | SGuiBack t ->
    let tt = type_of ctx bctx env t in
    require_present ctx env t tt ~use:"the gui target";
    (match tt with
    | TPlayer | TAny -> ()
    | _ -> err ctx t.epos "gui target must be a player (got %s)" (ty_to_string tt));
    (env, false)
  | SShowScoreboard (name, t) ->
    check_decl_name ctx st.spos "scoreboard" ctx.scoreboards name;
    check_ui_target ctx bctx env t ~what:"show a scoreboard";
    (env, false)
  | SHideScoreboard t ->
    check_ui_target ctx bctx env t ~what:"hide a scoreboard";
    (env, false)
  | SUpdateScoreboard t ->
    check_ui_target ctx bctx env t ~what:"update a scoreboard";
    (env, false)
  | SShowTablist (name, t) ->
    check_decl_name ctx st.spos "tablist" ctx.tablists name;
    check_ui_target ctx bctx env t ~what:"show a tablist";
    (env, false)
  | SHideTablist t ->
    check_ui_target ctx bctx env t ~what:"hide a tablist";
    (env, false)
  | SShowBossbar (name, t) ->
    check_decl_name ctx st.spos "bossbar" ctx.bossbars name;
    check_ui_target ctx bctx env t ~what:"show a bossbar";
    (env, false)
  | SHideBossbar (name, t) ->
    check_decl_name ctx st.spos "bossbar" ctx.bossbars name;
    check_ui_target ctx bctx env t ~what:"hide a bossbar";
    (env, false)
  | SClearTitle t ->
    check_ui_target ctx bctx env t ~what:"clear a title";
    (env, false)
  | SClearBelowname t ->
    check_ui_target ctx bctx env t ~what:"clear a belowname";
    (env, false)
  | SSetTablistPart (_, value, target) ->
    let vt = type_of ctx bctx env value in
    require_present ctx env value vt ~use:"the tablist text";
    check_ui_target ctx bctx env target ~what:"set a tablist part";
    (env, false)
  | STitle { t_title; t_subtitle; t_target; t_fade_in; t_stay; t_fade_out } ->
    let tt = type_of ctx bctx env t_title in
    require_present ctx env t_title tt ~use:"the title text";
    (match t_subtitle with
    | Some s ->
      let stt = type_of ctx bctx env s in
      require_present ctx env s stt ~use:"the subtitle text"
    | None -> ());
    List.iter
      (fun (d, label) ->
        match d with
        | Some n when n <= 0 -> err ctx st.spos "title %s duration must be positive" label
        | _ -> ())
      [ (t_fade_in, "fade-in"); (t_stay, "stay"); (t_fade_out, "fade-out") ];
    check_ui_target ctx bctx env t_target ~what:"show a title";
    (env, false)
  | SActionbar { ab_text; ab_target; ab_duration } ->
    let tt = type_of ctx bctx env ab_text in
    require_present ctx env ab_text tt ~use:"the actionbar text";
    (match ab_duration with
    | Some n when n <= 0 -> err ctx st.spos "actionbar duration must be positive"
    | _ -> ());
    check_ui_target ctx bctx env ab_target ~what:"show an actionbar";
    (env, false)
  | SSetBossbarPart { bp_name; bp_part; bp_value; bp_target } ->
    check_decl_name ctx st.spos "bossbar" ctx.bossbars bp_name;
    let vt = type_of ctx bctx env bp_value in
    require_present ctx env bp_value vt ~use:"the bossbar value";
    if bp_part = "progress" && not (num_ok vt) then
      err ctx bp_value.epos "bossbar progress must be a number (got %s)" (ty_to_string vt);
    check_ui_target ctx bctx env bp_target ~what:"update a bossbar";
    (env, false)
  | SBelowname (text, target) ->
    let tt = type_of ctx bctx env text in
    require_present ctx env text tt ~use:"the belowname text";
    check_ui_target ctx bctx env target ~what:"show a belowname";
    (env, false)
  | SSetBelownameScore (value, target) ->
    let vt = type_of ctx bctx env value in
    require_present ctx env value vt ~use:"the belowname score";
    if not (num_ok vt) then
      err ctx value.epos "belowname score must be a number (got %s)" (ty_to_string vt);
    check_ui_target ctx bctx env target ~what:"set a belowname score";
    (env, false)
  | SLine text ->
    let tt = type_of ctx bctx env text in
    require_present ctx env text tt ~use:"the line text";
    (env, false)
  | SBlank -> (env, false)
  | SEntry (text, skin) ->
    let tt = type_of ctx bctx env text in
    require_present ctx env text tt ~use:"the entry text";
    check_skin ctx bctx env st.spos skin;
    (env, false)
  | SFill skin ->
    check_skin ctx bctx env st.spos skin;
    (env, false)
  | SPersistSet (name, subject, value) ->
    let vt = type_of ctx bctx env value in
    require_present ctx env value vt ~use:"the assigned value";
    (match Hashtbl.find_opt ctx.persists name with
    | Some pi ->
      check_persist_subject ctx bctx env st.spos name pi subject;
      if not (param_compat pi.pi_ty vt) then
        err ctx value.epos "persistent '%s' has type %s; cannot assign %s" name
          (ty_to_string pi.pi_ty) (ty_to_string vt)
    | None -> err ctx st.spos "unknown persistent '%s'" name);
    (env, false)
  | SGiveItem { gi_id; gi_target; gi_amount } ->
    let idt = type_of ctx bctx env gi_id in
    require_present ctx env gi_id idt ~use:"the item id";
    (match idt with
    | TString | TAny -> ()
    | _ -> err ctx gi_id.epos "item id must be a String (got %s)" (ty_to_string idt));
    check_item_id_literal ctx gi_id ~allow_vanilla:false ~where:"'give item'";
    let tt = type_of ctx bctx env gi_target in
    require_present ctx env gi_target tt ~use:"the give target";
    (match tt with
    | TPlayer | TAny -> ()
    | _ -> err ctx gi_target.epos "give target must be a Player (got %s)" (ty_to_string tt));
    (match gi_amount with
    | Some a ->
      let at = type_of ctx bctx env a in
      require_present ctx env a at ~use:"the give amount";
      if not (num_ok at) then
        err ctx a.epos "give amount must be a number (got %s)" (ty_to_string at)
    | None -> ());
    (env, false)
  | SSpawnMob { sm_id; sm_at; sm_as } ->
    let idt = type_of ctx bctx env sm_id in
    require_present ctx env sm_id idt ~use:"the mob id";
    (match idt with
    | TString | TAny -> ()
    | _ -> err ctx sm_id.epos "mob id must be a String (got %s)" (ty_to_string idt));
    check_mob_id_literal ctx sm_id ~where:"'spawn mob'";
    let at = type_of ctx bctx env sm_at in
    require_present ctx env sm_at at ~use:"the spawn location";
    (match at with
    | TLocation | TAny -> ()
    | _ -> err ctx sm_at.epos "spawn location must be a Location (got %s)" (ty_to_string at));
    let env =
      match sm_as with
      | Some v ->
        check_persist_shadow ctx st.spos "spawn binding" v;
        bind env v TMob
      | None -> env
    in
    (env, false)
  | SDespawnMob e ->
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use:"the despawned mob";
    (match t with
    | TMob | TAny -> ()
    | _ -> err ctx e.epos "can only despawn mobs (got %s)" (ty_to_string t));
    (env, false)
  | SSetNametag { nt_part; nt_target; nt_value; nt_viewer } ->
    let tt = type_of ctx bctx env nt_target in
    require_present ctx env nt_target tt ~use:"the nametag target";
    (match tt with
    | TPlayer | TAny -> ()
    | _ -> err ctx nt_target.epos "nametag target must be a Player (got %s)" (ty_to_string tt));
    let vt = type_of ctx bctx env nt_value in
    require_present ctx env nt_value vt ~use:"the nametag value";
    (match vt with
    | TString | TAny -> ()
    | _ -> err ctx nt_value.epos "nametag value must be a String (got %s)" (ty_to_string vt));
    if nt_part = Some "color" then check_nametag_color_literal ctx nt_value;
    (match nt_viewer with
    | Some v -> check_ui_target ctx bctx env v ~what:"show a nametag"
    | None -> ());
    (env, false)
  | SResetNametag { rn_target; rn_viewer } ->
    let tt = type_of ctx bctx env rn_target in
    require_present ctx env rn_target tt ~use:"the nametag target";
    (match tt with
    | TPlayer | TAny -> ()
    | _ -> err ctx rn_target.epos "nametag target must be a Player (got %s)" (ty_to_string tt));
    (match rn_viewer with
    | Some v -> check_ui_target ctx bctx env v ~what:"reset a nametag"
    | None -> ());
    (env, false)
  | SSendPacket { sp_fields; sp_target; _ } ->
    (* packet names and field shapes are runtime-resolved by design (5D);
       the checker validates only the statement shape. A literal 'none' is
       the design-5D spelling of a null packet component *)
    List.iter
      (fun (_, v) ->
        let vt = type_of ctx bctx env v in
        match v.e with
        | ENone -> ()
        | _ -> require_present ctx env v vt ~use:"the packet field value")
      sp_fields;
    check_ui_target ctx bctx env sp_target ~what:"send a packet";
    (env, false)
  | SCancelPacket ->
    (if not bctx.packet then
       err ctx st.spos "'cancel packet' is only allowed inside a Packet handler"
     else if bctx.color = Async then
       err ctx st.spos "'cancel packet' must run before the handler goes async");
    (env, false)
  (* --- phase-6 display entities --- *)
  | SShowDisplay { sh_display; sh_target } ->
    check_display ctx bctx env sh_display;
    check_ui_target ctx bctx env sh_target ~what:"show a display";
    (env, false)
  | SHideDisplay { hi_display; hi_target } ->
    check_display ctx bctx env hi_display;
    check_ui_target ctx bctx env hi_target ~what:"hide a display";
    (env, false)
  | SMountDisplay { mo_display; mo_entity } ->
    check_display ctx bctx env mo_display;
    let et = type_of ctx bctx env mo_entity in
    require_present ctx env mo_entity et ~use:"the mount target";
    (match et with
    | TPlayer | TMob | TAny -> ()
    | _ ->
      err ctx mo_entity.epos "can only mount displays on players or mobs (got %s)"
        (ty_to_string et));
    (env, false)
  | STeleportDisplay { tp_display; tp_to } ->
    check_display ctx bctx env tp_display;
    let tt = type_of ctx bctx env tp_to in
    require_present ctx env tp_to tt ~use:"the teleport target";
    (match tt with
    | TLocation | TAny -> ()
    | _ ->
      err ctx tp_to.epos "display teleport target must be a Location (got %s)" (ty_to_string tt));
    (env, false)
  | SDestroyDisplay e ->
    check_display ctx bctx env e;
    (env, false)
  (* --- phase-6 http --- *)
  | SReply { rp_code; rp_body } ->
    if not bctx.api then
      err ctx st.spos "'reply' is only allowed inside an 'api' handler";
    (match rp_code with
    | Some c ->
      let ct = type_of ctx bctx env c in
      require_present ctx env c ct ~use:"the reply code";
      if not (num_ok ct) then
        err ctx c.epos "reply code must be a number (got %s)" (ty_to_string ct)
    | None -> ());
    let bt = type_of ctx bctx env rp_body in
    require_present ctx env rp_body bt ~use:"the reply body";
    (match bt with
    | TString | TAny -> ()
    | _ -> err ctx rp_body.epos "reply body must be a String (got %s)" (ty_to_string bt));
    (env, false)
  (* --- phase-6 NBS songs --- *)
  | SPlaySong { ps_song; ps_target; ps_tick; ps_at; ps_radius } ->
    check_string_arg ctx bctx env ps_song "the song file";
    (match ps_target with
    | Some t -> check_ui_target ctx bctx env t ~what:"play a song"
    | None -> ());
    check_num_opt ctx bctx env ps_tick "the start tick";
    (match ps_at with
    | Some at ->
      let at_t = type_of ctx bctx env at in
      require_present ctx env at at_t ~use:"the play location";
      (match at_t with
      | TLocation | TAny -> ()
      | _ -> err ctx at.epos "play location must be a Location (got %s)" (ty_to_string at_t))
    | None -> ());
    check_num_opt ctx bctx env ps_radius "the play radius";
    (env, false)
  | SPauseSong t | SResumeSong t | SStopSong t ->
    check_ui_target ctx bctx env t ~what:"control a song";
    (env, false)
  | SBroadcastSong e ->
    check_string_arg ctx bctx env e "the song file";
    (env, false)
  | SSongVolume { vo_target; vo_volume } ->
    check_ui_target ctx bctx env vo_target ~what:"set a song volume";
    check_num ctx bctx env vo_volume "the song volume";
    (env, false)
  | SFadeSong { fa_target; fa_volume; fa_ticks } ->
    check_ui_target ctx bctx env fa_target ~what:"fade a song";
    check_num ctx bctx env fa_volume "the fade volume";
    if fa_ticks <= 0 then err ctx st.spos "fade duration must be positive";
    (env, false)
  (* --- phase-6 blocks --- *)
  | SSetBlock { bl_at; bl_block } ->
    check_location_arg ctx bctx env bl_at "the block location";
    check_block_value_arg ctx bctx env bl_block "the block";
    (env, false)
  | SFillBlocks { fb_from; fb_to; fb_block } ->
    check_location_arg ctx bctx env fb_from "the fill start";
    check_location_arg ctx bctx env fb_to "the fill end";
    check_block_value_arg ctx bctx env fb_block "the block";
    (* design 6D: warn on large literal volumes — big fills freeze the tick
       thread *)
    (match (literal_coords fb_from, literal_coords fb_to) with
    | Some (x1, y1, z1), Some (x2, y2, z2) ->
      let axis a b = int_of_float (Float.abs (a -. b)) + 1 in
      let volume = axis x1 x2 * axis y1 y2 * axis z1 z2 in
      if volume > fill_blocks_warn_volume then
        warn ctx st.spos
          "'fill blocks' spans %d blocks here; fills over %d blocks can stall the tick thread"
          volume fill_blocks_warn_volume
    | _ -> ());
    (env, false)
  (* --- phase-6 sounds --- *)
  | SPlaySound { sn_sound; sn_target; sn_at; sn_volume; sn_pitch } ->
    check_string_arg ctx bctx env sn_sound "the sound name";
    check_ui_target ctx bctx env sn_target ~what:"play a sound";
    (match sn_at with
    | Some at -> check_location_arg ctx bctx env at "the sound location"
    | None -> ());
    check_num_opt ctx bctx env sn_volume "the sound volume";
    check_num_opt ctx bctx env sn_pitch "the sound pitch";
    (env, false)
  | SStopSound { so_sound; so_target } ->
    (match so_sound with
    | Some e -> check_string_arg ctx bctx env e "the sound name"
    | None -> ());
    check_ui_target ctx bctx env so_target ~what:"stop a sound";
    (env, false)
  (* --- phase-6 particles --- *)
  | SSpawnParticle { pa_particle; pa_at; pa_count; pa_offset; pa_speed; pa_viewer } ->
    check_string_arg ctx bctx env pa_particle "the particle name";
    check_location_arg ctx bctx env pa_at "the particle location";
    check_num_opt ctx bctx env pa_count "the particle count";
    (match pa_offset with
    | Some (x, y, z) ->
      check_num ctx bctx env x "the particle offset";
      check_num ctx bctx env y "the particle offset";
      check_num ctx bctx env z "the particle offset"
    | None -> ());
    check_num_opt ctx bctx env pa_speed "the particle speed";
    (match pa_viewer with
    | Some v -> check_ui_target ctx bctx env v ~what:"show a particle"
    | None -> ());
    (env, false)
  (* --- phase-6 MOTD --- *)
  | SSetServerMotd e ->
    check_string_arg ctx bctx env e "the motd";
    (env, false)
  (* --- phase-6 toasts --- *)
  | SShowToast { to_title; to_description; to_icon; to_frame; to_target } ->
    check_string_arg ctx bctx env to_title "the toast title";
    (match to_description with
    | Some d -> check_string_arg ctx bctx env d "the toast description"
    | None -> ());
    (match to_icon with
    | Some i -> check_string_arg ctx bctx env i "the toast icon"
    | None -> ());
    (match to_frame with
    | Some (f, fpos) ->
      if not (List.mem f toast_frames) then
        err ctx fpos "unknown toast frame '%s'; valid frames: %s%s" f
          (String.concat ", " toast_frames)
          (suggestion f toast_frames)
    | None -> ());
    check_ui_target ctx bctx env to_target ~what:"show a toast";
    (env, false)
  (* --- phase-6 map canvases --- *)
  | SDrawPixel { px_canvas; px_x; px_y; px_color } ->
    check_canvas ctx bctx env px_canvas;
    check_num ctx bctx env px_x "the pixel x coordinate";
    check_num ctx bctx env px_y "the pixel y coordinate";
    check_color_arg ctx bctx env px_color;
    (env, false)
  | SDrawRect { rc_canvas; rc_x1; rc_y1; rc_x2; rc_y2; rc_color } ->
    check_canvas ctx bctx env rc_canvas;
    check_num ctx bctx env rc_x1 "a rect coordinate";
    check_num ctx bctx env rc_y1 "a rect coordinate";
    check_num ctx bctx env rc_x2 "a rect coordinate";
    check_num ctx bctx env rc_y2 "a rect coordinate";
    check_color_arg ctx bctx env rc_color;
    (env, false)
  | SDrawText { tx_canvas; tx_x; tx_y; tx_text; tx_color } ->
    check_canvas ctx bctx env tx_canvas;
    check_num ctx bctx env tx_x "the text x coordinate";
    check_num ctx bctx env tx_y "the text y coordinate";
    check_string_arg ctx bctx env tx_text "the drawn text";
    check_color_arg ctx bctx env tx_color;
    (env, false)
  | SGiveMap { gm_canvas; gm_target } ->
    check_canvas ctx bctx env gm_canvas;
    let tt = type_of ctx bctx env gm_target in
    require_present ctx env gm_target tt ~use:"the give target";
    (match tt with
    | TPlayer | TAny -> ()
    | _ -> err ctx gm_target.epos "give target must be a Player (got %s)" (ty_to_string tt));
    (env, false)
  (* --- W-tasks: per-object task registry --- *)
  | STaskSet { tk_owner; tk_id = _; tk_value } ->
    check_task_owner ctx bctx env tk_owner;
    let vt = type_of ctx bctx env tk_value in
    require_present ctx env tk_value vt ~use:"the task";
    (match vt with
    | TSchedule | TAny -> ()
    | _ ->
      err ctx tk_value.epos
        "a task must be assigned a schedule (from a 'schedule ...' expression), got %s"
        (ty_to_string vt));
    (env, false)
  | STaskCancel { tc_owner; tc_id = _ } ->
    check_task_owner ctx bctx env tc_owner;
    (env, false)
  | SPlaceBlock { pb_block; pb_at } ->
    check_block_value_arg ctx bctx env pb_block "the placed block";
    check_location_arg ctx bctx env pb_at "the placement location";
    (env, false)
  | SRemoveBlock loc ->
    check_location_arg ctx bctx env loc "the block location";
    (env, false)
  (* --- phase-6 schedulers --- *)
  | SCancelSchedule e ->
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use:"the cancelled schedule";
    (* 'cancel schedule' takes a Schedule handle or a String name (scheduler v2) *)
    (match t with
    | TSchedule | TString | TAny -> ()
    | _ ->
      err ctx e.epos "can only cancel a schedule handle or a schedule name (got %s)"
        (ty_to_string t));
    check_schedule_name_literal ctx e ~where:"'cancel schedule'";
    (env, false)
  (* --- phase-6 worlds --- *)
  | SCreateWorld { cw_name; cw_loader; _ } ->
    check_string_arg ctx bctx env cw_name "the world name";
    check_loader ctx bctx env cw_loader;
    (env, false)
  | SLoadWorld { lw_name; lw_loader } ->
    check_string_arg ctx bctx env lw_name "the world name";
    check_loader ctx bctx env lw_loader;
    (env, false)
  | SUnloadWorld { uw_name; uw_teleport; _ } ->
    check_string_arg ctx bctx env uw_name "the world name";
    (match uw_teleport with
    | Some loc -> check_location_arg ctx bctx env loc "the evacuation location"
    | None -> ());
    (env, false)
  | SSaveWorld e ->
    check_string_arg ctx bctx env e "the world name";
    (env, false)
  | SCloneWorld { cl_from; cl_to; cl_loader } ->
    check_string_arg ctx bctx env cl_from "the source world name";
    check_string_arg ctx bctx env cl_to "the target world name";
    check_loader ctx bctx env cl_loader;
    (env, false)
  | SDeleteWorld { dw_name; dw_loader } ->
    check_string_arg ctx bctx env dw_name "the world name";
    check_loader ctx bctx env dw_loader;
    (env, false)
  | SImportWorld { iw_path; iw_name; iw_loader } ->
    check_string_arg ctx bctx env iw_path "the anvil world path";
    check_string_arg ctx bctx env iw_name "the world name";
    check_loader ctx bctx env iw_loader;
    (env, false)
  (* --- phase-7 entities --- *)
  | SSpawnEntity { se_type; se_at; se_as } ->
    check_string_arg ctx bctx env se_type "the entity type";
    check_entity_type_literal ctx se_type ~where:"'spawn entity'";
    check_location_arg ctx bctx env se_at "the spawn location";
    let env =
      match se_as with
      | Some v ->
        check_persist_shadow ctx st.spos "spawn binding" v;
        bind env v TEntity
      | None -> env
    in
    (env, false)
  | SRemoveEntity e ->
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use:"the removed entity";
    (match t with
    | TEntity | TMob | TDisplay | TAny -> ()
    | _ -> err ctx e.epos "can only remove entities (got %s)" (ty_to_string t));
    (env, false)
  | SMount { m_rider; m_vehicle } ->
    check_entity_arg ctx bctx env m_rider "the mounted entity";
    check_entity_arg ctx bctx env m_vehicle "the mount vehicle";
    (env, false)
  | SDismount e ->
    check_entity_arg ctx bctx env e "the dismounted entity";
    (env, false)
  | SLaunchProjectile { lp_type; lp_from; lp_velocity; lp_speed; lp_as } ->
    check_string_arg ctx bctx env lp_type "the projectile type";
    check_entity_type_literal ctx lp_type ~where:"'launch projectile'";
    let ft = type_of ctx bctx env lp_from in
    require_present ctx env lp_from ft ~use:"the shooter";
    (match ft with
    | TPlayer | TAny -> ()
    | _ -> err ctx lp_from.epos "projectiles launch from a Player (got %s)" (ty_to_string ft));
    (match lp_velocity with
    | Some v ->
      let vt = type_of ctx bctx env v in
      require_present ctx env v vt ~use:"the projectile velocity";
      (match vt with
      | TVec | TAny -> ()
      | _ ->
        err ctx v.epos
          "the projectile velocity must be a velocity vector (from velocity(x, y, z)), got %s"
          (ty_to_string vt))
    | None -> ());
    check_num_opt ctx bctx env lp_speed "the projectile speed";
    let env =
      match lp_as with
      | Some v ->
        check_persist_shadow ctx st.spos "launch binding" v;
        bind env v TEntity
      | None -> env
    in
    (env, false)
  | SDispenseFrom loc ->
    check_location_arg ctx bctx env loc "the dispenser location";
    (env, false)
  (* --- first-class holograms (GROUP D) --- *)
  | SShowHologram (name, t) ->
    check_decl_name ctx st.spos "hologram" ctx.holograms name;
    check_ui_target ctx bctx env t ~what:"show a hologram";
    (env, false)
  | SHideHologram (name, t) ->
    check_decl_name ctx st.spos "hologram" ctx.holograms name;
    check_ui_target ctx bctx env t ~what:"hide a hologram";
    (env, false)
  | SSetHologramLine { shl_name; shl_index; shl_value } ->
    check_decl_name ctx st.spos "hologram" ctx.holograms shl_name;
    let it = type_of ctx bctx env shl_index in
    require_present ctx env shl_index it ~use:"the hologram line index";
    (match it with
    | TInteger | TAny -> ()
    | _ -> err ctx shl_index.epos "hologram line index must be an Integer (got %s)" (ty_to_string it));
    let vt = type_of ctx bctx env shl_value in
    require_present ctx env shl_value vt ~use:"the hologram line text";
    (env, false)
  | SMoveHologram (name, loc) ->
    check_decl_name ctx st.spos "hologram" ctx.holograms name;
    check_location_arg ctx bctx env loc "the hologram location";
    (env, false)
  | SRemoveHologram name ->
    check_decl_name ctx st.spos "hologram" ctx.holograms name;
    (env, false)
  (* --- first-class npcs (GROUP C) --- *)
  | SSetNpcSkin { sns_name; sns_skin } ->
    check_decl_name ctx st.spos "npc" ctx.npcs sns_name;
    check_npc_skin ctx bctx env sns_skin;
    (env, false)
  | SSetNpcName { snn_name; snn_value } ->
    check_decl_name ctx st.spos "npc" ctx.npcs snn_name;
    check_string_arg ctx bctx env snn_value "the npc name";
    (env, false)
  | SSetNpcLocation { snl_name; snl_value } ->
    check_decl_name ctx st.spos "npc" ctx.npcs snl_name;
    check_location_arg ctx bctx env snl_value "the npc location";
    (env, false)
  | SRemoveNpc name ->
    check_decl_name ctx st.spos "npc" ctx.npcs name;
    (env, false)
  | SShowNpc (name, t) ->
    check_decl_name ctx st.spos "npc" ctx.npcs name;
    check_ui_target ctx bctx env t ~what:"show an npc";
    (env, false)
  | SHideNpc (name, t) ->
    check_decl_name ctx st.spos "npc" ctx.npcs name;
    check_ui_target ctx bctx env t ~what:"hide an npc";
    (env, false)
  (* --- W-viewers: entity viewer control + per-viewer nametag --- *)
  | SShowEntity { she_entity; she_target } ->
    check_viewer_entity ctx bctx env she_entity ~what:"show";
    check_ui_target ctx bctx env she_target ~what:"show an entity";
    (env, false)
  | SHideEntity { hie_entity; hie_target } ->
    check_viewer_entity ctx bctx env hie_entity ~what:"hide";
    check_ui_target ctx bctx env hie_target ~what:"hide an entity";
    (env, false)
  | SSetEntityName { sen_entity; sen_value; sen_viewer } ->
    check_viewer_entity ctx bctx env sen_entity ~what:"set the name of";
    let vt = type_of ctx bctx env sen_value in
    require_present ctx env sen_value vt ~use:"the entity name";
    (match vt with
    | TString | TAny -> ()
    | _ -> err ctx sen_value.epos "entity name must be a String (got %s)" (ty_to_string vt));
    (* the per-viewer nametag is sent to exactly one viewer: a single Player *)
    let vwt = type_of ctx bctx env sen_viewer in
    require_present ctx env sen_viewer vwt ~use:"the viewer";
    (match vwt with
    | TPlayer | TAny -> ()
    | _ ->
      err ctx sen_viewer.epos
        "the per-viewer name target must be a Player (got %s)" (ty_to_string vwt));
    (env, false)
  (* --- W-pvp: attribute modifiers (were add/remove_attribute_modifier) --- *)
  | SAddModifier { am_id; am_entity; am_attr; am_attr_pos; am_amount; am_op; am_op_pos } ->
    check_string_arg ctx bctx env am_id "the modifier id";
    check_entity_arg ctx bctx env am_entity "the modifier target";
    check_attribute_name ctx am_attr_pos am_attr;
    check_num ctx bctx env am_amount "the modifier amount";
    check_modifier_operation ctx am_op_pos am_op;
    (env, false)
  | SRemoveModifier { rm_id; rm_entity; rm_attr; rm_attr_pos } ->
    check_string_arg ctx bctx env rm_id "the modifier id";
    check_entity_arg ctx bctx env rm_entity "the modifier target";
    check_attribute_name ctx rm_attr_pos rm_attr;
    (env, false)
  (* --- W-pvp: combat effect verbs (were apply_*/spawn_projectile) --- *)
  | SDamage { dm_target; dm_amount; dm_type; dm_source } ->
    check_entity_arg ctx bctx env dm_target "the damage target";
    check_num ctx bctx env dm_amount "the damage amount";
    (match dm_type with
    | Some t ->
      check_string_arg ctx bctx env t "the damage type";
      check_damage_type_literal ctx t
    | None -> ());
    (match dm_source with
    | Some s -> check_entity_arg ctx bctx env s "the damage source"
    | None -> ());
    (env, false)
  | SKnock { kn_target; kn_from; kn_strength } ->
    check_entity_arg ctx bctx env kn_target "the knockback target";
    check_location_arg ctx bctx env kn_from "the knockback origin";
    check_num_opt ctx bctx env kn_strength "the knockback strength";
    (env, false)
  | SApplyEffect { ae_effect; ae_amplifier; ae_entity; ae_duration } ->
    check_string_arg ctx bctx env ae_effect "the effect type";
    check_potion_effect_literal ctx ae_effect;
    check_num ctx bctx env ae_amplifier "the effect amplifier";
    check_entity_arg ctx bctx env ae_entity "the effect target";
    check_num ctx bctx env ae_duration "the effect duration";
    (env, false)
  | SRemoveEffect { re_effect; re_entity } ->
    check_string_arg ctx bctx env re_effect "the effect type";
    check_potion_effect_literal ctx re_effect;
    check_entity_arg ctx bctx env re_entity "the effect target";
    (env, false)
  | SShoot { sh_type; sh_from; sh_velocity; sh_shooter } ->
    check_string_arg ctx bctx env sh_type "the projectile type";
    check_projectile_type_literal ctx sh_type;
    check_location_arg ctx bctx env sh_from "the projectile spawn location";
    (match sh_velocity with
    | Some v ->
      let vt = type_of ctx bctx env v in
      require_present ctx env v vt ~use:"the projectile velocity";
      (match vt with
      | TVec | TAny -> ()
      | _ ->
        err ctx v.epos
          "the projectile velocity must be a velocity vector (from velocity(x, y, z)), got %s"
          (ty_to_string vt))
    | None -> ());
    (match sh_shooter with
    | Some s -> check_entity_arg ctx bctx env s "the projectile shooter"
    | None -> ());
    (env, false)

(* loop bodies execute more than once: widen the entry env to a fixpoint of
   entry ⊔ post-body (quiet passes) so facts and types the body invalidates
   don't leak into the reported check; facts_of re-derives condition facts
   that genuinely hold at every iteration entry *)
and widen_loop ctx bctx env body ~facts_of =
  let env_equal a b = SM.equal ( = ) a.vars b.vars && SM.equal ( = ) a.facts b.facts in
  let rec fix base fuel =
    let entry = add_facts base (facts_of base) in
    let after, _ = with_quiet ctx (fun () -> check_stmt ctx bctx entry body) in
    let joined = join_env base after in
    if fuel = 0 || env_equal joined base then base else fix joined (fuel - 1)
  in
  let base = fix env 8 in
  add_facts base (facts_of base)

and restore_binding before after var =
  match var with
  | None -> after
  | Some v -> (
    match SM.find_opt v before.vars with
    | Some old -> { after with vars = SM.add v old after.vars }
    | None -> { after with vars = SM.remove v after.vars })

and check_ui_target ?(what = "show this") ctx bctx env t =
  let tt = type_of ctx bctx env t in
  require_present ctx env t tt ~use:"the target";
  if not (target_ok t tt) then
    err ctx t.epos "cannot %s to a %s; expected a Player, a list of players, or 'all'" what
      (ty_to_string tt)

(* W-viewers: the subject of show/hide/set-name must be a live entity — an
   Entity or a Mob (which is a subtype of Entity) *)
and check_viewer_entity ctx bctx env e ~what =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:"the entity";
  match unwrap t with
  | TEntity | TMob | TAny -> ()
  | _ ->
    err ctx e.epos "can only %s an entity or mob (got %s)" what (ty_to_string t)

(* --- phase-6 argument helpers --- *)

and check_string_arg ctx bctx env e what =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:what;
  match t with
  | TString | TAny -> ()
  | _ -> err ctx e.epos "%s must be a String (got %s)" what (ty_to_string t)

(* W-blocks: a block value argument accepts either a String id or a Block value
   (block(...) / block_at(...)) *)
and check_block_value_arg ctx bctx env e what =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:what;
  match t with
  | TString | TBlock | TAny -> ()
  | _ -> err ctx e.epos "%s must be a block id (String) or a Block value (got %s)" what (ty_to_string t)

and check_num ctx bctx env e what =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:what;
  if not (num_ok t) then err ctx e.epos "%s must be a number (got %s)" what (ty_to_string t)

and check_num_opt ctx bctx env e what =
  match e with
  | Some e -> check_num ctx bctx env e what
  | None -> ()

(* W-pvp: the <attr> in 'add/remove modifier ... <e>.<attr>' must name a real
   attribute key (the same list that backs the direct attribute properties) *)
and check_attribute_name ctx pos attr =
  if not (List.mem attr combat_attribute_names) then
    err ctx pos "unknown attribute '%s'; valid attributes: %s%s" attr
      (String.concat ", " combat_attribute_names)
      (suggestion attr combat_attribute_names)

(* W-pvp: the <operation> of 'add modifier' is one of add | add_multiplied_base
   | add_multiplied_total (the AttributeOperation enum) *)
and check_modifier_operation ctx pos op =
  let valid = [ "add"; "add_multiplied_base"; "add_multiplied_total" ] in
  if not (List.mem op valid) then
    err ctx pos "unknown modifier operation '%s'; valid operations: %s%s" op
      (String.concat ", " valid)
      (suggestion op valid)

(* W-tasks: the owner of a <obj>.tasks.<id> operation must be an object with a
   stable runtime identity (Player/Mob/Entity/Display/Block). Item is rejected
   with a targeted message — it is a value type with no per-object registry. *)
and check_task_owner ctx bctx env e =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:"the task owner";
  match unwrap t with
  | t when is_task_owner t -> ()
  | TItem ->
    err ctx e.epos
      "Item has no task registry; .tasks is only available on Player, Mob, Entity, Npc, \
       Hologram, and block_at(...) (items are value types with no stable identity)"
  | t ->
    err ctx e.epos
      "%s has no task registry; .tasks needs a Player, Mob, Entity, Display, or Block owner"
      (ty_to_string t)

and check_location_arg ctx bctx env e what =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:what;
  match t with
  | TLocation | TAny -> ()
  | _ -> err ctx e.epos "%s must be a Location (got %s)" what (ty_to_string t)

(* mount/dismount targets: anything that is an entity at runtime *)
and check_entity_arg ctx bctx env e what =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:what;
  match t with
  | TEntity | TMob | TPlayer | TDisplay | TAny -> ()
  | _ -> err ctx e.epos "%s must be an entity (got %s)" what (ty_to_string t)

and check_display ctx bctx env e =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:"the display";
  match t with
  | TDisplay | TAny -> ()
  | _ ->
    err ctx e.epos
      "expected a Display value (from spawn_text_display/spawn_item_display/\
       spawn_block_display), got %s"
      (ty_to_string t)

and check_canvas ctx bctx env e =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:"the canvas";
  match t with
  | TCanvas | TAny -> ()
  | _ -> err ctx e.epos "can only draw on a map canvas (got %s)" (ty_to_string t)

(* map colors: a color name (String) or a MapPalette index (number) *)
and check_color_arg ctx bctx env e =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:"the color";
  match t with
  | TString | TInteger | TDouble | TAny -> ()
  | _ ->
    err ctx e.epos "the color must be a color name or a palette index (got %s)" (ty_to_string t)

and check_loader ctx bctx env e =
  let t = type_of ctx bctx env e in
  require_present ctx env e t ~use:"the world loader";
  match t with
  | TWorldLoader | TAny -> ()
  | _ ->
    err ctx e.epos
      "expected a world loader (anvil_loader, polar_loader, or polar_storage_loader), got %s"
      (ty_to_string t)

(* literal location(x, y, z[, yaw, pitch]) coordinates, for the fill-volume
   warning *)
and literal_coords e =
  match e.e with
  | ECall ("location", (x :: y :: z :: _ as args))
    when List.length args = 3 || List.length args = 5 -> (
    match (fold_number x, fold_number y, fold_number z) with
    | Some fx, Some fy, Some fz -> Some (fx, fy, fz)
    | _ -> None)
  | _ -> None

and check_skin ctx bctx env pos skin =
  match skin with
  | SkBuiltin name ->
    if not (List.mem name tablist_skins) then
      err ctx pos "unknown tablist skin '%s'; valid skins: %s%s" name
        (String.concat ", " tablist_skins)
        (suggestion name tablist_skins)
  | SkPlayer e ->
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use:"the skin player";
    (match t with
    | TPlayer | TAny -> ()
    | _ -> err ctx e.epos "'skin of' expects a Player (got %s)" (ty_to_string t))
  | SkCustom (a, b) ->
    let ta = type_of ctx bctx env a in
    require_present ctx env a ta ~use:"the skin texture";
    let tb = type_of ctx bctx env b in
    require_present ctx env b tb ~use:"the skin signature"

(* npc skin form (GROUP C): a username String (Mojang-fetched) or
   skin(texture, signature) — both texture and signature are Strings *)
and check_npc_skin ctx bctx env sk =
  match sk with
  | NpcSkinUsername e ->
    let t = type_of ctx bctx env e in
    require_present ctx env e t ~use:"the npc skin username";
    (match t with
    | TString | TAny -> ()
    | _ -> err ctx e.epos "npc skin username must be a String (got %s)" (ty_to_string t))
  | NpcSkinTexture (a, b) ->
    let ta = type_of ctx bctx env a in
    require_present ctx env a ta ~use:"the skin texture";
    (match ta with
    | TString | TAny -> ()
    | _ -> err ctx a.epos "skin texture must be a String (got %s)" (ty_to_string ta));
    let tb = type_of ctx bctx env b in
    require_present ctx env b tb ~use:"the skin signature";
    (match tb with
    | TString | TAny -> ()
    | _ -> err ctx b.epos "skin signature must be a String (got %s)" (ty_to_string tb))

and check_set_prop ctx bctx env pos target name value =
  let vt = type_of ctx bctx env value in
  let env' =
    match path_of target with
    | Some parts -> invalidate_path env (parts @ [ name ])
    | None -> env
  in
  (match (target.e, bctx.args) with
  | EVar "args", Some args when not (SM.mem "args" env.vars) ->
    require_present ctx env value vt ~use:"the assigned value";
    if List.assoc_opt name args = None then
      err ctx pos "unknown argument '%s'%s" name (suggestion name (List.map fst args))
  | _ when
      (* item.tags.<path> leaf: a freeform NBT slot. It is a writable
         optional<Any>, so any scalar/list/compound value is legal and
         'set ... to none' deletes the tag — the value therefore carries no
         presence requirement (phase 9 §2). *)
      is_tags_ty (with_quiet ctx (fun () -> type_of ctx bctx env target))
      || inside_tags ctx bctx env target ->
    ()
  | _ -> (
    require_present ctx env value vt ~use:"the assigned value";
    let tt = type_of ctx bctx env target in
    require_present ctx env target tt ~use:"this value";
    let owner = unwrap tt in
    match owner with
    | TAny -> ()
    | TEither ts ->
      err ctx pos "cannot access property '%s' on either<%s>; narrow it first with 'is a'" name
        (String.concat "|" (List.map ty_to_string ts))
    | _ -> (
      match props_of_ty owner with
      | None -> err ctx pos "%s has no property '%s'" (ty_to_string owner) name
      | Some props -> (
        match find_prop owner name with
        | None ->
          err ctx pos "unknown property '%s' on %s%s" name (ty_to_string owner)
            (suggestion name (List.map (fun p -> p.p_name) props))
        | Some p ->
          if not p.p_writable then
            err ctx pos "property '%s' on %s is read-only" name (ty_to_string owner)
          else begin
            (match p.p_ty with
            | TInteger | TDouble ->
              if not (num_ok vt) then
                err ctx value.epos "property '%s' expects a number (got %s)" name
                  (ty_to_string vt)
            | TString ->
              (match vt with
              | TString | TAny -> ()
              | _ ->
                err ctx value.epos "property '%s' expects a String (got %s)" name
                  (ty_to_string vt));
              if owner = TPlayer && name = "gamemode" then
                check_gamemode_literal ctx value;
              if owner = TDisplay then check_display_string_literal ctx name value;
              if owner = TEntity && name = "pose" then check_pose_literal ctx value;
              if owner = TWorld && name = "weather" then check_weather_literal ctx value
            | TBoolean -> (
              match vt with
              | TBoolean | TAny -> ()
              | _ ->
                err ctx value.epos "property '%s' expects a Boolean (got %s)" name
                  (ty_to_string vt))
            | TWorld -> (
              match vt with
              | TWorld | TString | TAny -> ()
              | _ ->
                err ctx value.epos "property '%s' expects a World or world name (got %s)" name
                  (ty_to_string vt))
            | TLocation -> (
              match vt with
              | TLocation | TAny -> ()
              | _ ->
                err ctx value.epos "property '%s' expects a Location (got %s)" name
                  (ty_to_string vt))
            | TItem -> (
              match vt with
              | TItem | TAny -> ()
              | _ ->
                err ctx value.epos "property '%s' expects an Item (got %s)" name
                  (ty_to_string vt))
            | TList _ -> (
              match vt with
              | TList _ | TAny -> ()
              | _ ->
                err ctx value.epos "property '%s' expects a list (got %s)" name
                  (ty_to_string vt))
            | TSkin -> (
              match vt with
              | TSkin | TAny -> ()
              | _ ->
                err ctx value.epos
                  "property '%s' expects a Skin (from skin(texture, signature) or \
                   fetch_skin(name)), got %s"
                  name (ty_to_string vt))
            | TVec -> (
              match vt with
              | TVec | TAny -> ()
              | _ ->
                err ctx value.epos
                  "property '%s' expects a velocity vector (from velocity(x, y, z)), got %s"
                  name (ty_to_string vt))
            | _ -> ())
          end))));
  (env', false)

and check_stmts ctx bctx env ss =
  List.fold_left
    (fun (env, term) s ->
      let env', t = check_stmt ctx bctx env s in
      (env', term || t))
    (env, false) ss

let () = Tc_expr.check_stmts_ref := check_stmts
