open Ast
open Parser_state
open Parse_expr

let mks pos node = { s = node; spos = pos }

(* v1.5.0 phase 3: a synthetic local used to thread a single evaluation of a
   persistent-rooted place through an in-place nested mutation and its
   re-store. The '__' prefix is reserved (the checker only bars it for
   persistent decl names, so a local is free) and cannot collide with a
   user-written variable. *)
let place_counter = ref 0

let fresh_place_var () =
  incr place_counter;
  Printf.sprintf "__place_%d" !place_counter

(* W-tasks: destructure a parsed postfix expression into (owner, id) when it is a
   `<owner>.tasks.<id>` member access — the shape that keys the per-object task
   registry. Returns None for anything else. *)
let task_owner_id (e : Ast.expr) =
  match e.e with
  | EProp (inner, id) -> (
    match inner.e with
    | EProp (owner, "tasks") -> Some (owner, id)
    | _ -> None)
  | _ -> None

(* W-tasks: scan the token stream starting at index [i0] for a `.tasks.<id>`
   member access at bracket-depth 0, before the surrounding expression ends
   (a depth-0 'to'/'{', a closing bracket, or a non-postfix token). Bounded to
   the line of the first token so a bare 'stop' can never absorb the following
   statement. Routes 'set/stop <obj>.tasks.<id>' to the task path before the
   generic 'set'/bare-'stop' handlers run. *)
let tasks_member_ahead st i0 =
  let toks = st.tokens in
  let n = Array.length toks in
  if i0 >= n then false
  else begin
    let _, start_line, _ = toks.(i0) in
    let depth = ref 0 in
    let i = ref i0 in
    let found = ref false in
    let stop = ref false in
    while (not !stop) && (not !found) && !i < n do
      let t, line, _ = toks.(!i) in
      if line > start_line then stop := true
      else begin
        (match t with
        | Token.LPAREN | Token.LBRACKET -> incr depth
        | Token.RPAREN | Token.RBRACKET -> if !depth > 0 then decr depth else stop := true
        | Token.DOT when !depth = 0 ->
          let is_tasks =
            !i + 2 < n
            && (match toks.(!i + 1) with Token.IDENT "tasks", _, _ -> true | _ -> false)
            && (match toks.(!i + 2) with Token.DOT, _, _ -> true | _ -> false)
          in
          if is_tasks then found := true
        | Token.TO when !depth = 0 -> stop := true
        | Token.LBRACE when !depth = 0 -> stop := true
        | _ when !depth = 0 ->
          (* only ident-like/member words continue a postfix chain at depth 0;
             anything else ends the expression *)
          (match t with
          | Token.IDENT _ -> ()
          | _ when member_word t <> None -> ()
          | _ -> stop := true)
        | _ -> ());
        incr i
      end
    done;
    !found
  end

(* npc skin form (GROUP C), shared by the npc{} declaration and
   'set npc "n" skin ...': skin(texture, signature) direct properties, or a
   bare username String (Mojang-fetched at runtime) *)
let parse_npc_skin st =
  match peek_tok st with
  | Token.IDENT "skin" when peek2_tok st = Token.LPAREN ->
    ignore (advance st);
    ignore (advance st);
    let texture = parse_expr st in
    expect st Token.COMMA "',' between skin texture and signature";
    let signature = parse_expr st in
    expect st Token.RPAREN "')' to close skin(...)";
    NpcSkinTexture (texture, signature)
  | _ -> NpcSkinUsername (parse_expr st)

let starts_statement = function
  | Token.CANCEL | Token.SET | Token.IF | Token.SEND | Token.TELEPORT | Token.HALT
  | Token.BROADCAST | Token.LBRACE | Token.LOOP | Token.WHILE | Token.RETURN | Token.CALL
  | Token.IDENT _ ->
    true
  | _ -> false

let rec parse_statement st =
  let p = pos_here st in
  match peek_tok st with
  | Token.CANCEL -> (
    ignore (advance st);
    match peek_tok st with
    | Token.EVENT when peek2_tok st <> Token.DOT ->
      ignore (advance st);
      mks p SCancelEvent
    | Token.IDENT "packet" when peek2_tok st <> Token.DOT ->
      ignore (advance st);
      mks p SCancelPacket
    | Token.IDENT "schedule" ->
      ignore (advance st);
      mks p (SCancelSchedule (parse_expr st))
    | t when starts_expression t ->
      (* W-tasks: 'cancel <obj>.tasks.<id>' — cancel a named per-object task *)
      let e = parse_postfix st in
      (match task_owner_id e with
      | Some (owner, id) -> mks p (STaskCancel { tc_owner = owner; tc_id = id })
      | None ->
        error st
          "Expected 'event', 'packet', 'schedule', or a '<obj>.tasks.<id>' task after 'cancel'")
    | t ->
      error st (Printf.sprintf
                  "Expected 'event', 'packet', 'schedule', or a task after 'cancel', found %s"
                  (Token.describe t)))
  | Token.SET -> parse_set st p
  | Token.IF -> parse_if st
  | Token.SEND
    when soft2 st "packet"
         && (match peek3_tok st with Token.STRING _ -> true | _ -> false) ->
    ignore (advance st);
    ignore (advance st);
    let sp_name = expect_string st "packet name" in
    expect st Token.LBRACE "'{' after packet name";
    let sp_fields = parse_packet_fields st in
    expect st Token.RBRACE "'}' to close packet fields";
    expect st Token.TO "'to' in send packet statement";
    let sp_target = parse_target st in
    mks p (SSendPacket { sp_name; sp_fields; sp_target })
  | Token.SEND ->
    ignore (advance st);
    let message = parse_expr st in
    let target = if matches st Token.TO then Some (parse_target st) else None in
    mks p (SSend (message, target))
  | Token.TELEPORT when soft2 st "display" && peek3_tok st <> Token.TO ->
    (* teleport display <expr> to <location>; a variable actually named
       'display' still teleports through the plain form because its next
       token is 'to' *)
    ignore (advance st);
    ignore (advance st);
    let tp_display = parse_expr st in
    expect st Token.TO "'to' in teleport display statement";
    mks p (STeleportDisplay { tp_display; tp_to = parse_expr st })
  | Token.TELEPORT ->
    ignore (advance st);
    let entity = parse_expr st in
    expect st Token.TO "'to' in teleport command";
    mks p (STeleport (entity, parse_expr st))
  | Token.HALT ->
    ignore (advance st);
    mks p SHalt
  | Token.IDENT "stop"
    when (not (soft2 st "song")) && (not (soft2 st "sound"))
         && tasks_member_ahead st (st.pos + 1) ->
    (* W-tasks: 'stop <obj>.tasks.<id>' — an alias of 'cancel <obj>.tasks.<id>'.
       Detected by lookahead so it wins over bare 'stop' below. *)
    ignore (advance st);
    let e = parse_postfix st in
    (match task_owner_id e with
    | Some (owner, id) -> mks p (STaskCancel { tc_owner = owner; tc_id = id })
    | None -> error st "Expected a '<obj>.tasks.<id>' task after 'stop'")
  | Token.IDENT "stop"
    when peek2_tok st <> Token.LPAREN && (not (soft2 st "song")) && not (soft2 st "sound") ->
    (* bare 'stop': cancel the enclosing schedule (scheduler v2). 'stop song'
       and 'stop sound' below are the music forms *)
    ignore (advance st);
    mks p SStop
  | Token.IDENT "repeat"
    when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let rp_count = parse_expr st in
    expect st Token.TIMES "'times' after the repeat count";
    let rp_every = if eat_soft st "every" then Some (parse_duration st) else None in
    let rp_body = !lambda_body_ref st in
    mks p (SRepeat { rp_count; rp_every; rp_body })
  | Token.BROADCAST when soft2 st "song" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SBroadcastSong (parse_expr st))
  | Token.BROADCAST ->
    ignore (advance st);
    mks p (SBroadcast (parse_expr st))
  | Token.LBRACE -> parse_block st
  | Token.LOOP -> parse_loop st ~body:parse_block
  | Token.WHILE ->
    ignore (advance st);
    let condition = parse_expr st in
    mks p (SWhile (condition, parse_block st))
  | Token.RETURN ->
    ignore (advance st);
    (* the return value must start on the same line: otherwise a bare
       'return' in a brace-free guard would swallow the next statement *)
    if starts_expression (peek_tok st) && (pos_here st).line = p.line then
      mks p (SReturn (Some (parse_expr st)))
    else mks p (SReturn None)
  | Token.CALL when soft2 st "original" ->
    (* 'call original method' — invoke the overridden base receiver method
       (replaces the removed default()/super) with the current bound-variable
       values *)
    ignore (advance st);
    (* 'call' *)
    ignore (advance st);
    (* 'original' *)
    expect_soft st "method";
    (* the old trailing argument clause was removed: forward a changed value by
       mutating the bound variable before the bare call. Point at 'with' with a
       migration hint rather than the generic statement-start error. *)
    if soft st "with" then
      error st
        "'call original method' takes no arguments; mutate the bound variable before the bare \
         'call original method' to forward a changed value";
    mks p SCallOriginal
  | Token.CALL ->
    ignore (advance st);
    let name = expect_ident st "function name after 'call'" in
    expect st Token.LPAREN "'(' after function name";
    mks p (SCall (name, parse_call_args st))
  | Token.IDENT "wait" when starts_expression (peek2_tok st) ->
    ignore (advance st);
    let amount = parse_additive st in
    let unit =
      match peek_tok st with
      | Token.IDENT ("ticks" | "tick") ->
        ignore (advance st);
        "ticks"
      | Token.IDENT ("seconds" | "second") ->
        ignore (advance st);
        "seconds"
      | Token.IDENT "millis" ->
        ignore (advance st);
        "millis"
      | t ->
        error st
          (Printf.sprintf "Expected 'ticks', 'seconds', or 'millis' after wait amount, found %s"
             (Token.describe t))
    in
    mks p (SWait (amount, unit))
  | Token.IDENT "give" when soft2 st "item" ->
    ignore (advance st);
    ignore (advance st);
    let gi_id = parse_expr st in
    expect st Token.TO "'to' in give item statement";
    let gi_target = parse_expr st in
    let gi_amount = if eat_soft st "amount" then Some (parse_expr st) else None in
    mks p (SGiveItem { gi_id; gi_target; gi_amount })
  | Token.IDENT "give" when soft2 st "map" ->
    (* give map of <canvas> to <target> *)
    ignore (advance st);
    ignore (advance st);
    expect_soft st "of";
    let gm_canvas = parse_expr st in
    expect st Token.TO "'to' in give map statement";
    mks p (SGiveMap { gm_canvas; gm_target = parse_expr st })
  | Token.IDENT "spawn" when soft2 st "particle" && peek3_tok st <> Token.LPAREN ->
    (* spawn particle <name> at <loc> [count N] [offset x, y, z] [speed S]
       [to <viewer|all>] *)
    ignore (advance st);
    ignore (advance st);
    let pa_particle = parse_expr st in
    expect_soft st "at";
    let pa_at = parse_expr st in
    let pa_count = if eat_soft st "count" then Some (parse_expr st) else None in
    let pa_offset =
      if eat_soft st "offset" then begin
        let x = parse_expr st in
        expect st Token.COMMA "',' between particle offsets";
        let y = parse_expr st in
        expect st Token.COMMA "',' between particle offsets";
        Some (x, y, parse_expr st)
      end
      else None
    in
    let pa_speed = if eat_soft st "speed" then Some (parse_expr st) else None in
    let pa_viewer = if matches st Token.TO then Some (parse_target st) else None in
    mks p (SSpawnParticle { pa_particle; pa_at; pa_count; pa_offset; pa_speed; pa_viewer })
  | Token.IDENT "spawn" when soft2 st "mob" && peek3_tok st <> Token.LPAREN ->
    ignore (advance st);
    ignore (advance st);
    (* §2: 'spawn mob Ghoul' spawns by the compile-time custom type; 'spawn mob
       by id <expr>' is the data-driven dynamic spawn (base Mob). The old
       'spawn mob "id"' string form is gone. *)
    let sm_target =
      if soft st "by" then begin
        ignore (advance st);
        expect_soft st "id";
        MSById (parse_expr st)
      end
      else begin
        let mst_pos = pos_here st in
        match peek_tok st with
        | Token.IDENT name when name.[0] >= 'A' && name.[0] <= 'Z' ->
          ignore (advance st);
          MSByType { mst_name = name; mst_pos; mst_id = "" }
        | Token.STRING s ->
          error st
            (Printf.sprintf
               "types must start with an uppercase letter — write `spawn mob %s`; for a \
                data-driven id use `spawn mob by id \"%s\"`"
               (pascal_of_id s) s)
        | Token.IDENT name ->
          error st
            (Printf.sprintf "types must start with an uppercase letter — write `spawn mob %s`"
               (pascal_of_id name))
        | t ->
          error st
            (Printf.sprintf "Expected a Capitalized mob type name after 'spawn mob', found %s"
               (Token.describe t))
      end
    in
    expect_soft st "at";
    let sm_at = parse_expr st in
    let sm_as =
      if matches st Token.AS then Some (expect_ident st "variable name after 'as'") else None
    in
    mks p (SSpawnMob { sm_target; sm_at; sm_as })
  | Token.IDENT "despawn" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    mks p (SDespawnMob (parse_expr st))
  (* --- phase-7 entities --- *)
  | Token.IDENT "spawn" when soft2 st "entity" && peek3_tok st <> Token.LPAREN ->
    (* spawn entity "TYPE" at <location> [as e] *)
    ignore (advance st);
    ignore (advance st);
    let se_type = parse_expr st in
    expect_soft st "at";
    let se_at = parse_expr st in
    let se_as =
      if matches st Token.AS then Some (expect_ident st "variable name after 'as'") else None
    in
    mks p (SSpawnEntity { se_type; se_at; se_as })
  | Token.IDENT "remove" when soft2 st "entity" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SRemoveEntity (parse_expr st))
  | Token.IDENT "remove" when soft2 st "block" ->
    (* W-tasks/blocks: 'remove block at <location>' — set air and cancel every
       task bound to that position *)
    ignore (advance st);
    ignore (advance st);
    expect_soft st "at";
    mks p (SRemoveBlock (parse_expr st))
  | Token.IDENT "place"
    when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    (* W-blocks: 'place <Block|"id"> at <location>' — imperative block placement *)
    ignore (advance st);
    let pb_block = parse_expr st in
    expect_soft st "at";
    let pb_at = parse_expr st in
    mks p (SPlaceBlock { pb_block; pb_at })
  | Token.IDENT "dismount" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    mks p (SDismount (parse_expr st))
  | Token.IDENT "launch" when soft2 st "projectile" ->
    (* launch projectile "TYPE" from <shooter>
       [with velocity <vec> | with speed N] [as e] *)
    ignore (advance st);
    ignore (advance st);
    let lp_type = parse_expr st in
    expect_soft st "from";
    let lp_from = parse_expr st in
    let lp_velocity = ref None in
    let lp_speed = ref None in
    if eat_soft st "with" then begin
      if soft st "velocity" then begin
        ignore (advance st);
        lp_velocity := Some (parse_expr st)
      end
      else if soft st "speed" then begin
        ignore (advance st);
        lp_speed := Some (parse_expr st)
      end
      else
        error st
          (Printf.sprintf "Expected 'velocity' or 'speed' after 'with', found %s"
             (Token.describe (peek_tok st)))
    end;
    let lp_as =
      if matches st Token.AS then Some (expect_ident st "variable name after 'as'") else None
    in
    mks p
      (SLaunchProjectile
         { lp_type; lp_from; lp_velocity = !lp_velocity; lp_speed = !lp_speed; lp_as })
  (* --- phase-9 dispenser runtime: 'dispense from <location>' fires the
     dispenser/dropper block at that location (BlockDispense event) --- *)
  | Token.IDENT "dispense" when soft2 st "from" ->
    ignore (advance st);
    expect_soft st "from";
    mks p (SDispenseFrom (parse_expr st))
  (* --- W-pvp: combat effect verbs + attribute modifiers (replace the old
     apply_*/spawn_projectile/…_attribute_modifier free functions) --- *)
  | Token.IDENT "damage" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let dm_target = parse_expr st in
    expect_soft st "by";
    let dm_amount = parse_expr st in
    let dm_type = if matches st Token.AS then Some (parse_expr st) else None in
    let dm_source = if eat_soft st "from" then Some (parse_expr st) else None in
    mks p (SDamage { dm_target; dm_amount; dm_type; dm_source })
  | Token.IDENT "knock" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let kn_target = parse_expr st in
    expect_soft st "away";
    expect_soft st "from";
    let kn_from = parse_expr st in
    let kn_strength =
      if eat_soft st "with" then begin
        expect_soft st "strength";
        Some (parse_expr st)
      end
      else None
    in
    mks p (SKnock { kn_target; kn_from; kn_strength })
  | Token.IDENT "apply" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let ae_effect = parse_expr st in
    let ae_amplifier = parse_expr st in
    expect st Token.TO "'to' in apply statement";
    let ae_entity = parse_expr st in
    expect_soft st "for";
    let ae_duration = parse_expr st in
    mks p (SApplyEffect { ae_effect; ae_amplifier; ae_entity; ae_duration })
  | Token.IDENT "shoot" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let sh_type = parse_expr st in
    expect_soft st "from";
    let sh_from = parse_expr st in
    let sh_velocity =
      if eat_soft st "with" then begin
        expect_soft st "velocity";
        Some (parse_expr st)
      end
      else None
    in
    let sh_shooter = if eat_soft st "by" then Some (parse_expr st) else None in
    mks p (SShoot { sh_type; sh_from; sh_velocity; sh_shooter })
  | Token.IDENT "add" when soft2 st "modifier" ->
    ignore (advance st);
    ignore (advance st);
    let am_id = parse_expr st in
    expect st Token.TO "'to' in add modifier statement";
    let target = parse_postfix st in
    let am_entity, am_attr, am_attr_pos =
      match target.e with
      | EProp (ent, attr) -> (ent, attr, target.epos)
      | _ -> error st "expected '<entity>.<attribute>' after 'to' in add modifier statement"
    in
    expect_soft st "of";
    let am_amount = parse_expr st in
    let am_op_pos = pos_here st in
    let am_op =
      expect_ident st "the modifier operation (add, add_multiplied_base, or add_multiplied_total)"
    in
    mks p (SAddModifier { am_id; am_entity; am_attr; am_attr_pos; am_amount; am_op; am_op_pos })
  | Token.IDENT "remove" when soft2 st "modifier" ->
    ignore (advance st);
    ignore (advance st);
    let rm_id = parse_expr st in
    expect_soft st "from";
    let target = parse_postfix st in
    let rm_entity, rm_attr, rm_attr_pos =
      match target.e with
      | EProp (ent, attr) -> (ent, attr, target.epos)
      | _ -> error st "expected '<entity>.<attribute>' after 'from' in remove modifier statement"
    in
    mks p (SRemoveModifier { rm_id; rm_entity; rm_attr; rm_attr_pos })
  | Token.IDENT "remove" when (match peek2_tok st with Token.STRING _ -> true | _ -> false) ->
    ignore (advance st);
    let re_effect = parse_expr st in
    expect_soft st "from";
    let re_entity = parse_expr st in
    mks p (SRemoveEffect { re_effect; re_entity })
  | Token.IDENT "reset" when soft2 st "nametag" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "of";
    let rn_target = parse_expr st in
    let rn_viewer = if eat_soft st "for" then Some (parse_target st) else None in
    mks p (SResetNametag { rn_target; rn_viewer })
  (* --- phase-6 display entities --- *)
  | Token.IDENT "show" when soft2 st "display" ->
    ignore (advance st);
    ignore (advance st);
    let sh_display = parse_expr st in
    expect st Token.TO "'to' in show display statement";
    mks p (SShowDisplay { sh_display; sh_target = parse_target st })
  | Token.IDENT "hide" when soft2 st "display" ->
    ignore (advance st);
    ignore (advance st);
    let hi_display = parse_expr st in
    expect_soft st "from";
    mks p (SHideDisplay { hi_display; hi_target = parse_target st })
  | Token.IDENT "mount" when soft2 st "display" ->
    ignore (advance st);
    ignore (advance st);
    let mo_display = parse_expr st in
    expect_soft st "on";
    mks p (SMountDisplay { mo_display; mo_entity = parse_expr st })
  | Token.IDENT "mount" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    (* phase-7: mount <rider> on <vehicle> — any entity on any entity *)
    ignore (advance st);
    let m_rider = parse_expr st in
    expect_soft st "on";
    mks p (SMount { m_rider; m_vehicle = parse_expr st })
  | Token.IDENT "destroy" when soft2 st "display" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SDestroyDisplay (parse_expr st))
  (* --- phase-6 http --- *)
  | Token.IDENT "reply" when soft2 st "with" || soft2 st "code" ->
    (* reply [code N] with <string-expr> *)
    ignore (advance st);
    let rp_code = if eat_soft st "code" then Some (parse_expr st) else None in
    expect_soft st "with";
    mks p (SReply { rp_code; rp_body = parse_expr st })
  (* --- phase-6 NBS songs --- *)
  | Token.IDENT "play" when soft2 st "song" ->
    (* play song <file> to <target> [at tick N]
       play song <file> at <location> radius <r> *)
    ignore (advance st);
    ignore (advance st);
    let ps_song = parse_expr st in
    if matches st Token.TO then begin
      let target = parse_target st in
      let tick =
        if soft st "at" && soft2 st "tick" then begin
          ignore (advance st);
          ignore (advance st);
          Some (parse_expr st)
        end
        else None
      in
      mks p
        (SPlaySong
           { ps_song; ps_target = Some target; ps_tick = tick; ps_at = None; ps_radius = None })
    end
    else if eat_soft st "at" then begin
      let at = parse_expr st in
      expect_soft st "radius";
      mks p
        (SPlaySong
           {
             ps_song;
             ps_target = None;
             ps_tick = None;
             ps_at = Some at;
             ps_radius = Some (parse_expr st);
           })
    end
    else
      error st
        (Printf.sprintf "Expected 'to <target>' or 'at <location> radius <r>' after the song, \
                         found %s"
           (Token.describe (peek_tok st)))
  | Token.IDENT ("pause" | "resume" | "stop") when soft2 st "song" ->
    let word = expect_ident st "'pause', 'resume', or 'stop'" in
    ignore (advance st);
    expect_soft st "of";
    let target = parse_target st in
    mks p
      (match word with
      | "pause" -> SPauseSong target
      | "resume" -> SResumeSong target
      | _ -> SStopSong target)
  | Token.IDENT "fade" when soft2 st "song" ->
    (* fade song of <target> to <volume> over <duration> *)
    ignore (advance st);
    ignore (advance st);
    expect_soft st "of";
    let fa_target = parse_target st in
    expect st Token.TO "'to' in fade song statement";
    let fa_volume = parse_expr st in
    expect_soft st "over";
    mks p (SFadeSong { fa_target; fa_volume; fa_ticks = parse_duration st })
  (* --- phase-6 sounds --- *)
  | Token.IDENT "play" when soft2 st "sound" ->
    (* play sound <name> to <target> [at <loc>] [volume V] [pitch P] *)
    ignore (advance st);
    ignore (advance st);
    let sn_sound = parse_expr st in
    expect st Token.TO "'to' in play sound statement";
    let sn_target = parse_target st in
    let sn_at = if eat_soft st "at" then Some (parse_expr st) else None in
    let sn_volume = if eat_soft st "volume" then Some (parse_expr st) else None in
    let sn_pitch = if eat_soft st "pitch" then Some (parse_expr st) else None in
    mks p (SPlaySound { sn_sound; sn_target; sn_at; sn_volume; sn_pitch })
  | Token.IDENT "stop" when soft2 st "sound" ->
    (* stop sound [<name>] for <target> *)
    ignore (advance st);
    ignore (advance st);
    let so_sound = if soft st "for" then None else Some (parse_expr st) in
    expect_soft st "for";
    mks p (SStopSound { so_sound; so_target = parse_target st })
  (* --- phase-6 blocks --- *)
  | Token.IDENT "fill" when soft2 st "blocks" ->
    (* fill blocks from <loc> to <loc> with <block> *)
    ignore (advance st);
    ignore (advance st);
    expect_soft st "from";
    let fb_from = parse_expr st in
    expect st Token.TO "'to' in fill blocks statement";
    let fb_to = parse_expr st in
    expect_soft st "with";
    mks p (SFillBlocks { fb_from; fb_to; fb_block = parse_expr st })
  (* --- phase-6 toasts --- *)
  | Token.IDENT "show" when soft2 st "toast" ->
    (* show toast <title> [description <d>] [icon <material>]
       [frame task|goal|challenge] to <target> *)
    ignore (advance st);
    ignore (advance st);
    let to_title = parse_expr st in
    let to_description = if eat_soft st "description" then Some (parse_expr st) else None in
    let to_icon = if eat_soft st "icon" then Some (parse_expr st) else None in
    let to_frame =
      if eat_soft st "frame" then begin
        let fpos = pos_here st in
        Some (expect_ident st "toast frame name", fpos)
      end
      else None
    in
    expect st Token.TO "'to' in show toast statement";
    mks p (SShowToast { to_title; to_description; to_icon; to_frame; to_target = parse_target st })
  (* --- phase-6 map canvases --- *)
  | Token.IDENT "draw" when soft2 st "pixel" || soft2 st "rect" || soft2 st "text" -> (
    ignore (advance st);
    let shape = expect_ident st "'pixel', 'rect', or 'text'" in
    expect_soft st "on";
    let canvas = parse_expr st in
    match shape with
    | "pixel" ->
      (* draw pixel on <canvas> at <x>, <y> color <c> *)
      expect_soft st "at";
      let px_x = parse_expr st in
      expect st Token.COMMA "',' between pixel coordinates";
      let px_y = parse_expr st in
      expect_soft st "color";
      mks p (SDrawPixel { px_canvas = canvas; px_x; px_y; px_color = parse_expr st })
    | "rect" ->
      (* draw rect on <canvas> from <x1>, <y1> to <x2>, <y2> color <c> *)
      expect_soft st "from";
      let rc_x1 = parse_expr st in
      expect st Token.COMMA "',' between rect coordinates";
      let rc_y1 = parse_expr st in
      expect st Token.TO "'to' in draw rect statement";
      let rc_x2 = parse_expr st in
      expect st Token.COMMA "',' between rect coordinates";
      let rc_y2 = parse_expr st in
      expect_soft st "color";
      mks p (SDrawRect { rc_canvas = canvas; rc_x1; rc_y1; rc_x2; rc_y2; rc_color = parse_expr st })
    | _ ->
      (* draw text on <canvas> at <x>, <y> text <s> color <c> *)
      expect_soft st "at";
      let tx_x = parse_expr st in
      expect st Token.COMMA "',' between text coordinates";
      let tx_y = parse_expr st in
      expect_soft st "text";
      let tx_text = parse_expr st in
      expect_soft st "color";
      mks p (SDrawText { tx_canvas = canvas; tx_x; tx_y; tx_text; tx_color = parse_expr st }))
  (* --- phase-6 worlds --- *)
  | Token.IDENT "create" when soft2 st "world" ->
    (* create world <name> [readonly] with <loader> *)
    ignore (advance st);
    ignore (advance st);
    let cw_name = parse_expr st in
    let cw_readonly = eat_soft st "readonly" in
    expect_soft st "with";
    mks p (SCreateWorld { cw_name; cw_readonly; cw_loader = parse_expr st })
  | Token.IDENT "load" when soft2 st "world" ->
    ignore (advance st);
    ignore (advance st);
    let lw_name = parse_expr st in
    expect_soft st "with";
    mks p (SLoadWorld { lw_name; lw_loader = parse_expr st })
  | Token.IDENT "unload" when soft2 st "world" ->
    (* unload world <name> [without saving] [teleporting players to <loc>] *)
    ignore (advance st);
    ignore (advance st);
    let uw_name = parse_expr st in
    let uw_save =
      if soft st "without" then begin
        ignore (advance st);
        expect_soft st "saving";
        false
      end
      else true
    in
    let uw_teleport =
      if soft st "teleporting" then begin
        ignore (advance st);
        expect st Token.PLAYERS "'players' after 'teleporting'";
        expect st Token.TO "'to' after 'teleporting players'";
        Some (parse_expr st)
      end
      else None
    in
    mks p (SUnloadWorld { uw_name; uw_save; uw_teleport })
  | Token.IDENT "save" when soft2 st "world" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SSaveWorld (parse_expr st))
  | Token.IDENT "clone" when soft2 st "world" ->
    (* clone world <a> to <b> with <loader> *)
    ignore (advance st);
    ignore (advance st);
    let cl_from = parse_expr st in
    expect st Token.TO "'to' in clone world statement";
    let cl_to = parse_expr st in
    expect_soft st "with";
    mks p (SCloneWorld { cl_from; cl_to; cl_loader = parse_expr st })
  | Token.IDENT "delete" when soft2 st "world" ->
    ignore (advance st);
    ignore (advance st);
    let dw_name = parse_expr st in
    expect_soft st "with";
    mks p (SDeleteWorld { dw_name; dw_loader = parse_expr st })
  | Token.IDENT "import" when soft2 st "anvil" ->
    (* import anvil world <path> as <name> with <loader> *)
    ignore (advance st);
    ignore (advance st);
    expect_soft st "world";
    let iw_path = parse_expr st in
    expect st Token.AS "'as' in import anvil world statement";
    let iw_name = parse_expr st in
    expect_soft st "with";
    mks p (SImportWorld { iw_path; iw_name; iw_loader = parse_expr st })
  | Token.IDENT "spawn" when peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let name = expect_ident st "function name after 'spawn'" in
    expect st Token.LPAREN "'(' after function name";
    mks p (SSpawn (name, parse_call_args st))
  | Token.IDENT "async" when starts_statement (peek2_tok st) ->
    ignore (advance st);
    mks p (SAsyncBlock (parse_body st))
  | Token.IDENT "open" when soft2 st "gui" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SOpenGui (parse_gui_open st))
  | Token.IDENT "replace" when soft2 st "gui" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SReplaceGui (parse_gui_open st))
  | Token.IDENT "close" when soft2 st "gui" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "for";
    mks p (SCloseGui (parse_target st))
  | Token.IDENT "go" when soft2 st "back" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "for";
    mks p (SGuiBack (parse_target st))
  | Token.IDENT "show" when soft2 st "scoreboard" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "scoreboard name" in
    expect st Token.TO "'to' after scoreboard name";
    mks p (SShowScoreboard (name, parse_target st))
  | Token.IDENT "hide" when soft2 st "scoreboard" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "from";
    mks p (SHideScoreboard (parse_target st))
  | Token.IDENT "update" when soft2 st "scoreboard" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "for";
    mks p (SUpdateScoreboard (parse_target st))
  | Token.IDENT "show" when soft2 st "tablist" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "tablist name" in
    expect st Token.TO "'to' after tablist name";
    mks p (SShowTablist (name, parse_target st))
  | Token.IDENT "hide" when soft2 st "tablist" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "from";
    mks p (SHideTablist (parse_target st))
  | Token.IDENT "show" when soft2 st "bossbar" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "bossbar name" in
    expect st Token.TO "'to' after bossbar name";
    mks p (SShowBossbar (name, parse_target st))
  | Token.IDENT "hide" when soft2 st "bossbar" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "bossbar name" in
    expect_soft st "from";
    mks p (SHideBossbar (name, parse_target st))
  (* --- first-class holograms (GROUP D) --- *)
  | Token.IDENT "show" when soft2 st "hologram" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "hologram name" in
    expect st Token.TO "'to' after hologram name";
    mks p (SShowHologram (name, parse_target st))
  | Token.IDENT "hide" when soft2 st "hologram" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "hologram name" in
    expect_soft st "from";
    mks p (SHideHologram (name, parse_target st))
  | Token.IDENT "move" when soft2 st "hologram" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "hologram name" in
    expect st Token.TO "'to' in move hologram statement";
    mks p (SMoveHologram (name, parse_expr st))
  | Token.IDENT "remove" when soft2 st "hologram" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SRemoveHologram (expect_string st "hologram name"))
  (* --- first-class npcs (GROUP C) --- *)
  | Token.IDENT "remove" when soft2 st "npc" ->
    ignore (advance st);
    ignore (advance st);
    mks p (SRemoveNpc (expect_string st "npc name"))
  (* W-viewers §2: 'show npc "n" to <target>' / 'hide npc "n" from <target>' —
     name-keyed, matched (like the hologram forms) BEFORE the generic entity
     show/hide branch below *)
  | Token.IDENT "show" when soft2 st "npc" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "npc name" in
    expect st Token.TO "'to' after npc name";
    mks p (SShowNpc (name, parse_target st))
  | Token.IDENT "hide" when soft2 st "npc" ->
    ignore (advance st);
    ignore (advance st);
    let name = expect_string st "npc name" in
    expect_soft st "from";
    mks p (SHideNpc (name, parse_target st))
  (* --- W-viewers: entity viewer control (must come AFTER every UI show/hide
     form above; the UI keyword branches — scoreboard/tablist/bossbar/hologram/
     display/toast — are matched first, so this only fires on an entity
     expression like 'show z to p' / 'hide mob from attacker') --- *)
  | Token.IDENT "show" ->
    ignore (advance st);
    let she_entity = parse_expr st in
    expect st Token.TO "'to' in show statement";
    mks p (SShowEntity { she_entity; she_target = parse_target st })
  | Token.IDENT "hide" ->
    ignore (advance st);
    let hie_entity = parse_expr st in
    expect_soft st "from";
    mks p (SHideEntity { hie_entity; hie_target = parse_target st })
  | Token.IDENT "title" when starts_expression (peek2_tok st) ->
    ignore (advance st);
    let title = parse_expr st in
    let subtitle = if eat_soft st "subtitle" then Some (parse_expr st) else None in
    expect st Token.TO "'to' in title statement";
    let target = parse_target st in
    let fade_in = ref None in
    let stay = ref None in
    let fade_out = ref None in
    let continue = ref true in
    while !continue do
      if soft st "fade" then begin
        ignore (advance st);
        match peek_tok st with
        | Token.IDENT "in" ->
          ignore (advance st);
          fade_in := Some (parse_duration st)
        | Token.IDENT "out" ->
          ignore (advance st);
          fade_out := Some (parse_duration st)
        | t -> error st (Printf.sprintf "Expected 'in' or 'out' after 'fade', found %s" (Token.describe t))
      end
      else if soft st "stay" then begin
        ignore (advance st);
        stay := Some (parse_duration st)
      end
      else continue := false
    done;
    mks p
      (STitle
         { t_title = title; t_subtitle = subtitle; t_target = target;
           t_fade_in = !fade_in; t_stay = !stay; t_fade_out = !fade_out })
  | Token.IDENT "clear" when soft2 st "title" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "for";
    mks p (SClearTitle (parse_target st))
  | Token.IDENT "actionbar" when starts_expression (peek2_tok st) ->
    ignore (advance st);
    let text = parse_expr st in
    expect st Token.TO "'to' in actionbar statement";
    let target = parse_target st in
    let duration = if eat_soft st "for" then Some (parse_duration st) else None in
    mks p (SActionbar { ab_text = text; ab_target = target; ab_duration = duration })
  | Token.IDENT "belowname" when starts_expression (peek2_tok st) ->
    ignore (advance st);
    let text = parse_expr st in
    expect_soft st "for";
    mks p (SBelowname (text, parse_target st))
  | Token.IDENT "clear" when soft2 st "belowname" ->
    ignore (advance st);
    ignore (advance st);
    expect_soft st "for";
    mks p (SClearBelowname (parse_target st))
  (* removed DICTIONARY free builtins as a statement call (map_set(...), ...) *)
  | Token.IDENT name
    when peek2_tok st = Token.LPAREN && List.mem_assoc name removed_map_builtins ->
    error st (List.assoc name removed_map_builtins)
  (* natural list mutation: 'add x to l' -> l.add(x), reusing the .add method
     emit. 'add modifier ...' is matched earlier, so 'add' stays a soft keyword
     that is only a list-append at statement head when followed by an operand. *)
  | Token.IDENT "add" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let x = parse_expr st in
    expect st Token.TO "'to' in 'add <item> to <list>'";
    mks p (SMethodCall (parse_postfix st, "add", [ x ]))
  (* natural list mutation: 'remove x from l' -> l.remove(x). The specific
     remove-entity/block/modifier/effect/hologram/npc forms are matched earlier;
     the 'from <list>' tail confirms this collection form. *)
  | Token.IDENT "remove" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    let x = parse_expr st in
    expect_soft st "from";
    mks p (SMethodCall (parse_postfix st, "remove", [ x ]))
  (* natural map/list clear: 'clear c' -> c.clear(). 'clear title'/'clear
     belowname' are matched earlier. *)
  | Token.IDENT "clear" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    mks p (SMethodCall (parse_postfix st, "clear", []))
  (* natural map delete: 'delete m at k' -> map_delete(m, k), reusing the
     existing map_delete emit. 'delete world' is matched earlier.

     When the deleted-from place is rooted at a PERSISTENT name the mutation must
     be re-stored (like the persist-aware 'set ... at'): map_delete alone mutates
     the cached collection in place but never marks the row dirty (so the change
     is lost on the next flush/restart) nor rebuilds the reactive liveness index
     (so a removed reactive struct instance would keep reacting, §4.2). Thread it
     through persist_set so the row is dirtied, re-serialized, and the index is
     rebuilt. Non-persistent deletes keep the bare map_delete emit. *)
  | Token.IDENT "delete" when starts_expression (peek2_tok st) && peek2_tok st <> Token.LPAREN ->
    ignore (advance st);
    (match persist_lookup st (peek_tok st) with
    | Some (name, keyed) ->
      ignore (advance st);
      let subject =
        if keyed && soft st "for" then begin
          ignore (advance st);
          Some (parse_postfix st)
        end
        else None
      in
      finish_persist_delete st p name subject
    | None ->
      let mapexpr = parse_postfix st in
      expect_soft st "at";
      let key = parse_expr st in
      mks p (SCall ("map_delete", [ mapexpr; key ])))
  | Token.IDENT name when peek2_tok st = Token.LPAREN ->
    ignore (advance st);
    ignore (advance st);
    mks p (SCall (name, parse_call_args st))
  | (Token.IDENT _ | Token.EVENT) when peek2_tok st = Token.DOT ->
    (* W-collections: a bare method-call statement — <receiver>.<name>(args).
       Parse the postfix expression; only a method call (not a bare property
       read) is a valid statement here. *)
    let e = parse_postfix st in
    (match e.e with
    | EMethod (recv, name, args) -> mks e.epos (SMethodCall (recv, name, args))
    | _ ->
      error st
        "expected a method call like 'list.add(x)' or an assignment like 'set ... to ...'")
  | tok ->
    error st (Printf.sprintf "Unexpected %s at start of statement" (Token.describe tok))

and parse_set st p =
  ignore (advance st);
  if tasks_member_ahead st st.pos then begin
    (* W-tasks: 'set <obj>.tasks.<id> to <schedule-expr>' — associate a named
       task with the owner. The owner may be any postfix expression (a variable,
       a member chain, or block_at(loc)), so parse the whole lvalue with
       parse_postfix rather than the ident-chain parse_lvalue. *)
    let lvalue = parse_postfix st in
    expect st Token.TO "'to' after the task in 'set'";
    let value = parse_expr st in
    match task_owner_id lvalue with
    | Some (owner, id) -> mks p (STaskSet { tk_owner = owner; tk_id = id; tk_value = value })
    | None -> error st "Expected a '<obj>.tasks.<id>' target in this task assignment"
  end
  else if soft st "tablist" && (soft2 st "header" || soft2 st "footer") then begin
    ignore (advance st);
    let part = expect_ident st "'header' or 'footer'" in
    expect st Token.TO "'to' in set tablist statement";
    let value = parse_expr st in
    expect_soft st "for";
    mks p (SSetTablistPart (part, value, parse_target st))
  end
  else if
    soft st "bossbar"
    && match peek2_tok st with Token.STRING _ -> true | _ -> false
  then begin
    ignore (advance st);
    let name = expect_string st "bossbar name" in
    let part = expect_ident st "'progress' or 'text'" in
    if part <> "progress" && part <> "text" then
      error st (Printf.sprintf "Expected 'progress' or 'text', found '%s'" part);
    expect st Token.TO "'to' in set bossbar statement";
    let value = parse_expr st in
    expect_soft st "for";
    mks p (SSetBossbarPart { bp_name = name; bp_part = part; bp_value = value; bp_target = parse_target st })
  end
  else if soft st "belowname" && soft2 st "score" then begin
    ignore (advance st);
    ignore (advance st);
    expect st Token.TO "'to' in set belowname statement";
    let value = parse_expr st in
    expect_soft st "for";
    mks p (SSetBelownameScore (value, parse_target st))
  end
  else if soft st "song" && soft2 st "volume" then begin
    (* set song volume of <target> to <volume> *)
    ignore (advance st);
    ignore (advance st);
    expect_soft st "of";
    let vo_target = parse_target st in
    expect st Token.TO "'to' in set song volume statement";
    mks p (SSongVolume { vo_target; vo_volume = parse_expr st })
  end
  else if soft st "block" && soft2 st "at" then begin
    (* set block at <location> to <block> *)
    ignore (advance st);
    ignore (advance st);
    let bl_at = parse_expr st in
    expect st Token.TO "'to' in set block statement";
    mks p (SSetBlock { bl_at; bl_block = parse_expr st })
  end
  else if soft st "server" && soft2 st "motd" then begin
    (* set server motd to <expr> *)
    ignore (advance st);
    ignore (advance st);
    expect st Token.TO "'to' in set server motd statement";
    mks p (SSetServerMotd (parse_expr st))
  end
  else if soft st "name" && soft2 st "of" then begin
    (* W-viewers: 'set name of <entity> to <String> for <player>' — sets the
       entity's overhead name for THAT viewer only (per-viewer metadata) *)
    ignore (advance st);
    ignore (advance st);
    let sen_entity = parse_expr st in
    expect st Token.TO "'to' in set name statement";
    let sen_value = parse_expr st in
    expect_soft st "for";
    let sen_viewer = parse_target st in
    mks p (SSetEntityName { sen_entity; sen_value; sen_viewer })
  end
  else if
    soft st "nametag"
    && (soft2 st "of" || soft2 st "prefix" || soft2 st "suffix" || soft2 st "color")
  then begin
    ignore (advance st);
    let nt_part =
      match peek_tok st with
      | Token.IDENT (("prefix" | "suffix" | "color") as part) ->
        ignore (advance st);
        Some part
      | _ -> None
    in
    expect_soft st "of";
    let nt_target = parse_expr st in
    expect st Token.TO "'to' in set nametag statement";
    let nt_value =
      (* 'set nametag color of p to red' — a bare color name reads as a
         string literal, validated against the NamedTextColor names *)
      match (nt_part, peek_tok st) with
      | Some "color", Token.IDENT name
        when peek2_tok st <> Token.DOT && peek2_tok st <> Token.LPAREN ->
        let vp = pos_here st in
        ignore (advance st);
        mke vp (EString name)
      | _ -> parse_expr st
    in
    let nt_viewer = if eat_soft st "for" then Some (parse_target st) else None in
    mks p (SSetNametag { nt_part; nt_target; nt_value; nt_viewer })
  end
  else if
    soft st "hologram"
    && match peek2_tok st with Token.STRING _ -> true | _ -> false
  then begin
    (* set hologram "n" line <k> to <expr> *)
    ignore (advance st);
    let name = expect_string st "hologram name" in
    expect_soft st "line";
    let index = parse_expr st in
    expect st Token.TO "'to' in set hologram line statement";
    mks p (SSetHologramLine { shl_name = name; shl_index = index; shl_value = parse_expr st })
  end
  else if
    soft st "npc" && match peek2_tok st with Token.STRING _ -> true | _ -> false
  then begin
    (* set npc "n" skin <form> / name <expr> / location <expr> *)
    ignore (advance st);
    let name = expect_string st "npc name" in
    match peek_tok st with
    | Token.IDENT "skin" ->
      ignore (advance st);
      mks p (SSetNpcSkin { sns_name = name; sns_skin = parse_npc_skin st })
    | Token.IDENT "name" ->
      ignore (advance st);
      mks p (SSetNpcName { snn_name = name; snn_value = parse_expr st })
    | Token.IDENT "location" ->
      ignore (advance st);
      mks p (SSetNpcLocation { snl_name = name; snl_value = parse_expr st })
    | t ->
      error st
        (Printf.sprintf "Expected 'skin', 'name', or 'location' after npc name in 'set npc', \
                         found %s"
           (Token.describe t))
  end
  else if peek_tok st = Token.LPAREN && persist_lookup st (peek2_tok st) <> None then begin
    (* v1.5.0 phase 3: a parenthesized persistent place root — '(g).field' or
       the keyed '(g for subj).field' / '(g for subj) at k'. The parens bind the
       trailing '.field' / '[k]' / 'at k' to the persistent place instead of
       letting a keyed subject's own postfix expression greedily absorb it. *)
    ignore (advance st);
    let name, keyed =
      match persist_lookup st (peek_tok st) with Some x -> x | None -> assert false
    in
    ignore (advance st);
    let subject =
      if keyed then begin
        expect_soft st "for";
        Some (parse_postfix st)
      end
      else None
    in
    expect st Token.RPAREN "')' to close the persistent place";
    finish_persist_place st p name subject
  end
  else if persist_lookup st (peek_tok st) <> None then begin
    (* a place rooted at a persistent name: 'set g ...', 'set g for subj ...',
       'set g.field ...', 'set g at k ...'. A keyed subject is a postfix
       expression, so a '.field' after a bare 'g for subj' would attach to the
       subject — write '(g for subj).field' (handled above) to reach a field. *)
    let name, keyed =
      match persist_lookup st (peek_tok st) with Some x -> x | None -> assert false
    in
    ignore (advance st);
    let subject =
      if keyed && soft st "for" then begin
        ignore (advance st);
        Some (parse_postfix st)
      end
      else None
    in
    finish_persist_place st p name subject
  end
  else begin
    let lvalue = parse_lvalue st in
    if peek_tok st = Token.LBRACKET then begin
      (* map index-set with bracket syntax: 'set m[k] to v' (and the typed-tag
         form 'set mob.tags.hits[attacker] to N') desugars to map_set(m, k, v) *)
      ignore (advance st);
      let key = parse_expr st in
      expect st Token.RBRACKET "']' after map index in 'set'";
      expect st Token.TO "'to' after map index in 'set'";
      let value = parse_expr st in
      mks p (SCall ("map_set", [ lvalue; key; value ]))
    end
    else if eat_soft st "at" then begin
      (* map index-set sugar: 'set m at k to v' desugars to map_set(m, k, v)
         (phase 10) *)
      let key = parse_expr st in
      expect st Token.TO "'to' after map key in 'set ... at'";
      let value = parse_expr st in
      mks p (SCall ("map_set", [ lvalue; key; value ]))
    end
    else begin
      expect st Token.TO "'to' after variable name in 'set'";
      let value = parse_expr st in
      match lvalue.e with
      | EVar name -> mks p (SAssign (name, value))
      | EProp (target, name) -> mks lvalue.epos (SSetProp (target, name, value))
      | _ -> error st "Invalid assignment target"
    end
  end

(* v1.5.0 phase 3: finish a 'set' whose LHS is a place rooted at a persistent
   [name] with optional [subject]. Parses any '.field' / '[key]' segments, then
   a terminal 'at k'? and 'to value'.

   With no segments this reproduces the legacy persistent set: a whole-value
   reassignment ('set g to v') or a top-level collection index-set threaded
   through persist_set ('set g at k to v' desugars to
   persist_set(g, map_set(persist_get g, k, v)) — persist_get hands out the
   row's map/list, map_set mutates and returns it, persist_set stores it back so
   the change reaches the backend on the next flush).

   With segments this is a nested in-place mutation of a persistent struct /
   collection. Because the store holds the value by reference, mutating it in
   place is visible immediately; to make it DURABLE the row must be re-stored so
   the flush marks it dirty and re-serializes the whole blob. A single
   evaluation of the root is bound to a fresh temp, the mutation runs through
   that temp, and the SAME object is stored back — correct for present rows (the
   temp is the cached reference) and for absent rows (get() hands out a fresh
   copy that only becomes durable once re-stored). *)
and finish_persist_place st p name subject =
  let segs = ref [] in
  let go = ref true in
  while !go do
    match peek_tok st with
    | Token.DOT ->
      ignore (advance st);
      let hp = pos_here st in
      let field = expect_member_word st "field name after '.'" in
      segs := `Field (hp, field) :: !segs
    | Token.LBRACKET ->
      let hp = pos_here st in
      ignore (advance st);
      let key = parse_expr st in
      expect st Token.RBRACKET "']' to close index in 'set'";
      segs := `Index (hp, key) :: !segs
    | _ -> go := false
  done;
  let segs = List.rev !segs in
  match segs with
  | [] ->
    if eat_soft st "at" then begin
      let key = parse_expr st in
      expect st Token.TO "'to' after map key in 'set ... at'";
      let value = parse_expr st in
      let mapexpr = mke p (EPersistGet (name, subject)) in
      let updated = mke p (ECall ("map_set", [ mapexpr; key; value ])) in
      mks p (SPersistSet (name, subject, updated))
    end
    else begin
      expect st Token.TO "'to' after variable name in 'set'";
      mks p (SPersistSet (name, subject, parse_expr st))
    end
  | _ ->
    let read_fold base hs =
      List.fold_left
        (fun e h ->
          match h with
          | `Field (hp, f) -> mke hp (EProp (e, f))
          | `Index (hp, k) -> mke hp (ECall ("map_get", [ e; k ])))
        base hs
    in
    let tmp = fresh_place_var () in
    let mutation =
      if eat_soft st "at" then begin
        let key = parse_expr st in
        expect st Token.TO "'to' after map key in 'set ... at'";
        let value = parse_expr st in
        let parent = read_fold (mke p (EVar tmp)) segs in
        mks p (SCall ("map_set", [ parent; key; value ]))
      end
      else begin
        expect st Token.TO "'to' after the place in 'set'";
        let value = parse_expr st in
        let rec split = function
          | [ last ] -> ([], last)
          | x :: rest ->
            let init, last = split rest in
            (x :: init, last)
          | [] -> assert false
        in
        let init, last = split segs in
        let parent = read_fold (mke p (EVar tmp)) init in
        match last with
        | `Field (hp, f) -> mks hp (SSetProp (parent, f, value))
        | `Index (hp, k) -> mks hp (SCall ("map_set", [ parent; k; value ]))
      end
    in
    let bind = mks p (SAssign (tmp, mke p (EPersistGet (name, subject)))) in
    let writeback = mks p (SPersistSet (name, subject, mke p (EVar tmp))) in
    mks p (SBlock [ bind; mutation; writeback ])

(* v1.5.0 phase 3: finish a 'delete <persistent place> at k'. Mirrors
   {!finish_persist_place}: parses any '.field' / '[key]' segments to reach the
   collection, then the terminal 'at k', and re-stores the mutated root through
   persist_set so the delete is durable (row marked dirty) and the reactive
   liveness index rebuilds (§4.2 teardown). map_delete returns the mutated
   collection, so the no-segment case threads it straight through persist_set;
   the nested case binds the root to a temp, deletes through it, and stores the
   SAME object back. *)
and finish_persist_delete st p name subject =
  let segs = ref [] in
  let go = ref true in
  while !go do
    match peek_tok st with
    | Token.DOT ->
      ignore (advance st);
      let hp = pos_here st in
      let field = expect_member_word st "field name after '.'" in
      segs := `Field (hp, field) :: !segs
    | Token.LBRACKET ->
      let hp = pos_here st in
      ignore (advance st);
      let key = parse_expr st in
      expect st Token.RBRACKET "']' to close index in 'delete'";
      segs := `Index (hp, key) :: !segs
    | _ -> go := false
  done;
  let segs = List.rev !segs in
  expect_soft st "at";
  let key = parse_expr st in
  let read_fold base hs =
    List.fold_left
      (fun e h ->
        match h with
        | `Field (hp, f) -> mke hp (EProp (e, f))
        | `Index (hp, k) -> mke hp (ECall ("map_get", [ e; k ])))
      base hs
  in
  match segs with
  | [] ->
    let mapexpr = mke p (EPersistGet (name, subject)) in
    let updated = mke p (ECall ("map_delete", [ mapexpr; key ])) in
    mks p (SPersistSet (name, subject, updated))
  | _ ->
    let tmp = fresh_place_var () in
    let parent = read_fold (mke p (EVar tmp)) segs in
    let bind = mks p (SAssign (tmp, mke p (EPersistGet (name, subject)))) in
    let mutation = mks p (SCall ("map_delete", [ parent; key ])) in
    let writeback = mks p (SPersistSet (name, subject, mke p (EVar tmp))) in
    mks p (SBlock [ bind; mutation; writeback ])

(* send packet field maps: key: expr pairs; a '{ ... }' value is a nested field
   map (for TeamsPacket actions and other nested records), emitted as EMap; a
   '[ ... ]' value is a list whose items may themselves be nested '{ ... }'
   maps (design 5D nested records inside lists — the shape of
   PlayerInfoUpdatePacket's entries/properties) *)
and parse_packet_fields st =
  let fields = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    let key = expect_ident_like st "packet field name" in
    expect st Token.COLON "':' after packet field name";
    let value = parse_packet_value st in
    fields := (key, value) :: !fields;
    ignore (matches st Token.COMMA)
  done;
  List.rev !fields

and parse_packet_value st =
  if peek_tok st = Token.LBRACE then begin
    let vpos = pos_here st in
    ignore (advance st);
    let nested = parse_packet_fields st in
    expect st Token.RBRACE "'}' to close nested packet object";
    { e = EMap nested; epos = vpos }
  end
  else if peek_tok st = Token.LBRACKET then begin
    let vpos = pos_here st in
    ignore (advance st);
    let items = ref [] in
    if peek_tok st <> Token.RBRACKET then begin
      items := [ parse_packet_value st ];
      while matches st Token.COMMA do
        items := parse_packet_value st :: !items
      done
    end;
    expect st Token.RBRACKET "']' to close packet field list";
    { e = EList (List.rev !items); epos = vpos }
  end
  else parse_expr st

and parse_gui_open st =
  let go_name = expect_string st "gui name" in
  expect st Token.TO "'to' after gui name";
  let go_target = parse_target st in
  let go_init =
    if eat_soft st "with" then begin
      expect st Token.LBRACE "'{' after 'with'";
      let entries = ref [] in
      while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
        let key = expect_ident st "state key" in
        expect st Token.COLON "':' after state key";
        entries := (key, parse_expr st) :: !entries;
        ignore (matches st Token.COMMA)
      done;
      expect st Token.RBRACE "'}' to close state map";
      List.rev !entries
    end
    else []
  in
  { go_name; go_target; go_init }

and parse_loop st ~body =
  let p = pos_here st in
  ignore (advance st);
  if soft st "first" then begin
    ignore (advance st);
    let limit = parse_additive st in
    expect_soft st "of";
    let iter = parse_expr st in
    expect st Token.AS "'as' after loop expression";
    let var = expect_ident st "variable name after 'as'" in
    mks p (SForeach { fe_var = var; fe_limit = Some limit; fe_iter = iter; fe_body = body st })
  end
  else begin
    let iter = parse_expr st in
    if matches st Token.TIMES then begin
      let var =
        if matches st Token.AS then Some (expect_ident st "variable name after 'as'") else None
      in
      mks p (SLoop (iter, var, body st))
    end
    else if matches st Token.AS then begin
      let var = expect_ident st "variable name after 'as'" in
      if matches st Token.ARROW then begin
        (* map foreach (phase 10): 'loop m as key -> value { body }' *)
        let vvar = expect_ident st "value variable name after '->'" in
        mks p (SForeachMap { fm_key = var; fm_val = vvar; fm_map = iter; fm_body = body st })
      end
      else mks p (SForeach { fe_var = var; fe_limit = None; fe_iter = iter; fe_body = body st })
    end
    else error st "Expected 'times' or 'as' after loop expression"
  end

and parse_if st =
  let p = pos_here st in
  expect st Token.IF "'if'";
  let condition = parse_expr st in
  let then_branch = parse_block st in
  let else_branch =
    if matches st Token.ELSE then
      match peek_tok st with
      | Token.IF -> Some (parse_if st)
      | _ -> Some (parse_block st)
    else None
  in
  mks p (SIf (condition, then_branch, else_branch))

(* Statement bodies take '{ statements }' or exactly one brace-free statement;
   a brace-free 'if' body is itself a statement, so a following 'else' binds
   to the nearest 'if' *)
and parse_block st =
  let p = pos_here st in
  mks p (SBlock (parse_body st))

and parse_body st =
  if peek_tok st = Token.LBRACE then parse_braced_statements st
  else [ parse_statement st ]

and parse_braced_statements st =
  expect st Token.LBRACE "'{'";
  let stmts = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    stmts := parse_statement st :: !stmts
  done;
  expect st Token.RBRACE "'}'";
  List.rev !stmts

(* --- inline event handlers on item/mob/hologram/npc declarations
   (W-inline-handlers): on_<event>(binder, ...) { body }, with a brace-free
   one-liner body. The leading on_<event> IDENT is still on the token stream;
   this reads it, an optional parenthesized binder list, and the body. The
   binder names are user-chosen; their types are fixed by the kind's handler
   table and bound at typecheck time. *)
let starts_with_on name = String.length name > 3 && String.sub name 0 3 = "on_"

let parse_inline_handler st =
  let ih_pos = pos_here st in
  let ih_event = expect_ident st "handler name" in
  if peek_tok st = Token.LPAREN then
    error st
      (Printf.sprintf
         "handler '%s' takes no parameter list; write '%s { }' — the receiver and the event's \
          values are bound as bare variables in scope"
         ih_event ih_event);
  let ih_body = parse_body st in
  { ih_event; ih_body; ih_pos }

(* --- restricted DSL blocks (scoreboard lines { } / tablist column { }) --- *)

type dsl_ctx = DslLines | DslColumn

let rec parse_dsl_statement st ctx =
  let p = pos_here st in
  match peek_tok st with
  | Token.IDENT "line" when ctx = DslLines ->
    ignore (advance st);
    mks p (SLine (parse_expr st))
  | Token.IDENT "blank" when ctx = DslLines ->
    ignore (advance st);
    mks p SBlank
  | Token.IDENT "entry" when ctx = DslColumn ->
    ignore (advance st);
    let text = parse_expr st in
    mks p (SEntry (text, parse_opt_skin st))
  | Token.IDENT "fill" when ctx = DslColumn ->
    ignore (advance st);
    mks p (SFill (parse_opt_skin st))
  | Token.IF ->
    ignore (advance st);
    let condition = parse_expr st in
    let then_branch = parse_dsl_block st ctx in
    let else_branch =
      if matches st Token.ELSE then
        match peek_tok st with
        | Token.IF -> Some (parse_dsl_else_if st ctx)
        | Token.LBRACE -> Some (parse_dsl_block st ctx)
        | _ -> error st "Expected '{' or 'if' after 'else'"
      else None
    in
    mks p (SIf (condition, then_branch, else_branch))
  | Token.LOOP -> parse_loop st ~body:(fun st -> parse_dsl_block st ctx)
  | t ->
    let allowed = match ctx with
      | DslLines -> "'line', 'blank', 'if', and 'loop' are allowed inside 'lines { }'"
      | DslColumn -> "'entry', 'fill', 'if', and 'loop' are allowed inside 'column { }'"
    in
    error st (Printf.sprintf "Unexpected %s: only %s" (Token.describe t) allowed)

and parse_dsl_else_if st ctx =
  let p = pos_here st in
  expect st Token.IF "'if'";
  let condition = parse_expr st in
  let then_branch = parse_dsl_block st ctx in
  let else_branch =
    if matches st Token.ELSE then
      match peek_tok st with
      | Token.IF -> Some (parse_dsl_else_if st ctx)
      | Token.LBRACE -> Some (parse_dsl_block st ctx)
      | _ -> error st "Expected '{' or 'if' after 'else'"
    else None
  in
  mks p (SIf (condition, then_branch, else_branch))

and parse_dsl_block st ctx =
  let p = pos_here st in
  expect st Token.LBRACE "'{'";
  let stmts = ref [] in
  while peek_tok st <> Token.RBRACE && peek_tok st <> Token.EOF do
    stmts := parse_dsl_statement st ctx :: !stmts
  done;
  expect st Token.RBRACE "'}'";
  mks p (SBlock (List.rev !stmts))

and parse_opt_skin st =
  if eat_soft st "with" then begin
    expect_soft st "skin";
    match peek_tok st with
    | Token.IDENT "of" ->
      ignore (advance st);
      SkPlayer (parse_expr st)
    | Token.IDENT "custom" when peek2_tok st = Token.LPAREN ->
      ignore (advance st);
      ignore (advance st);
      let texture = parse_expr st in
      expect st Token.COMMA "',' between skin texture and signature";
      let signature = parse_expr st in
      expect st Token.RPAREN "')' to close custom skin";
      SkCustom (texture, signature)
    | Token.IDENT name ->
      ignore (advance st);
      SkBuiltin name
    | t -> error st (Printf.sprintf "Expected skin, found %s" (Token.describe t))
  end
  else SkBuiltin "gray"

let () = Parse_expr.lambda_body_ref := parse_body
