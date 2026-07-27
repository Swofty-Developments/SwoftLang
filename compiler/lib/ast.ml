type pos = {
  line : int;
  col : int;
}

type data_type =
  | DSimple of string
  | DEither of data_type list
  | DOptional of data_type
  | DList of data_type
  (* v1.8.0 futures: Future<T> in a type position (a param/field/return holding a
     handle to async work). PascalCase generic like List<T>. *)
  | DFuture of data_type
  (* map<K, V>: K in {String, Integer} (phase 11). map<V> parses to
     DMap (DSimple "STRING", V) — String keys are the back-compat default. *)
  | DMap of data_type * data_type

type param = {
  p_name : string;
  p_type : data_type option;
  p_pos : pos;
}

(* Storage backend config: used by storage{} blocks and, since phase 6, by
   the polar_storage_loader(...) world-loader expression, which reuses the
   exact same backend syntax (design 6B). *)
type backend =
  | BFiles of string
  | BSqlite of string
  | BMysql of { host : string; port : int; database : string; user : string; password : string }
  | BMongodb of string

(* a map<K, V> literal key: a String literal or an Integer literal. The int is
   carried as its source text so emit can render it as a JSON int (phase 11). *)
type map_key =
  | MKStr of string
  | MKInt of string

type expr = {
  e : expr_node;
  epos : pos;
}

and expr_node =
  | EString of string
  | ENumber of { value : string; integer : bool }
  | EBool of bool
  | ENone
  | EVar of string
  | EType of string
  | EBinary of string * expr * expr
  | EUnary of string * expr
  | ECall of string * expr list
  (* W-collections: method call on a receiver — <receiver>.<name>(<args>).
     Resolves by the receiver's static type (list<T>/map<K,V>/String) against
     the per-type method tables in registry.ml. Pure methods are expressions;
     mutating methods are statements (SMethodCall). *)
  | EMethod of expr * string * expr list
  | EAllPlayers
  | EList of expr list
  | EProp of expr * string
  | EPersistGet of string * expr option
  | ELambda of { lam_async : bool; lam_params : param list; lam_body : stmt list }
  (* nested field map inside 'send packet' values, e.g. action: { type: "...", ... } *)
  | EMap of (string * expr) list
  (* §1 struct construction: `Struct { field: expr, ... }`. The first component
     is the Capitalized struct type name; the second is the supplied fields in
     source order. Totality (every non-default field supplied) and per-field
     type-checking are enforced by the typechecker. *)
  | EStructNew of string * (string * expr) list
  (* map<K, V> literal in value position: { "key": expr, ... } or { 1: expr, ... }.
     Keys are all String or all Integer (phase 11); mixed keys are a checker
     error. Distinct from EMap (packet field records with ident keys). *)
  | EMapLit of (map_key * expr) list
  (* polar_storage_loader(<backend config>) — a world loader over a
     SwoftStorage backend, same syntax as storage{} backends (design 6B) *)
  | ELoaderStorage of backend
  (* W-tasks: `<obj>.tasks.<id> is running` — a Boolean that reports whether the
     named task is currently scheduled on the owner. tr_owner is the owning
     object expression, tr_id the task id. *)
  | ETaskRunning of { tr_owner : expr; tr_id : string }
  (* schedule [after <dur>] [every <dur>] [as "name"] { body } — returns a
     Schedule value; the body is async-colored and runs on the AsyncRuntime.
     'run' (1-based iteration counter) and 'stop' are bound inside the body *)
  | ESchedule of {
      sc_after : int option;
      sc_every : int option;
      sc_name : string option;
      sc_body : stmt list;
    }
  (* v1.8.0 futures §2: `spawn <call>` as an EXPRESSION yields Future<T> where T
     is the spawned async callable's inferred return type. The bare-statement
     form (SSpawn) stays fire-and-forget; this is the value-producing form used
     wherever an expression is expected (set x to spawn f(...), await spawn ...,
     list literals of futures). *)
  | EFutureSpawn of string * expr list
  (* v1.8.0 futures §2: `async { <stmts> ; <trailing?> }` as an EXPRESSION yields
     Future<typeof trailing> (Future<Unit> with no trailing expression). The
     statement form (SAsyncBlock) stays fire-and-forget. *)
  | EAsyncExpr of { ae_body : stmt list; ae_trailing : expr option }
  (* v1.8.0 futures §3.1: `await <Future<T>>` EXPRESSION -> T. Legal only in async
     context (same color gate as `wait`); suspends the vthread until resolved. *)
  | EAwait of expr
  (* v1.8.0 futures §4: `all of <List<Future<T>>>` -> Future<List<T>> and
     `any of <List<Future<T>>>` -> Future<T>. *)
  | EAllOf of expr
  | EAnyOf of expr

and skin =
  | SkBuiltin of string
  | SkPlayer of expr
  | SkCustom of expr * expr

(* npc skin form (first-class npc construct): a bare username String (fetched
   from Mojang, async+cached at runtime) OR skin(texture, signature) direct
   properties. Distinct from the tablist-entry `skin` above, which offers the
   builtin palette / 'skin of <player>' forms. *)
and npc_skin =
  | NpcSkinUsername of expr
  | NpcSkinTexture of expr * expr

and stmt = {
  s : stmt_node;
  spos : pos;
}

and stmt_node =
  | SSend of expr * expr option
  | SBroadcast of expr
  | STeleport of expr * expr
  | SHalt
  | SCancelEvent
  | SIf of expr * stmt * stmt option
  | SBlock of stmt list
  | SAssign of string * expr
  | SSetProp of expr * string * expr
  | SLoop of expr * string option * stmt
  | SWhile of expr * stmt
  | SForeach of { fe_var : string; fe_limit : expr option; fe_iter : expr; fe_body : stmt }
  (* map foreach (phase 10): loop m as key -> value { body } — binds the String
     key and the V value over each entry of the map *)
  | SForeachMap of { fm_key : string; fm_val : string; fm_map : expr; fm_body : stmt }
  | SCall of string * expr list
  (* 'call original method' — inside a custom declaration method that overrides
     a base receiver method, re-invoke the base (overridden) method. It re-runs
     with the current bound-variable values, so mutate a bound var beforehand to
     forward a changed value. *)
  | SCallOriginal
  (* W-collections: a bare method-call statement — <receiver>.<name>(<args>) —
     for the in-place mutating methods (list add/remove/..., map set/delete/...).
     Carries the receiver, method name, and arguments. *)
  | SMethodCall of expr * string * expr list
  | SReturn of expr option
  | SWait of expr * string
  | SSpawn of string * expr list
  | SAsyncBlock of stmt list
  (* v1.8.0 futures §4: positional tuple destructure `set (a, b) to <expr>`,
     scoped to await/all-of. Binds each name to the corresponding element type of
     a list-literal of futures under `await all of [...]`. *)
  | STupleBind of { tb_names : string list; tb_value : expr }
  | SOpenGui of gui_open
  | SReplaceGui of gui_open
  | SCloseGui of expr
  | SGuiBack of expr
  | SShowScoreboard of string * expr
  | SHideScoreboard of expr
  | SUpdateScoreboard of expr
  | SShowTablist of string * expr
  | SHideTablist of expr
  | SSetTablistPart of string * expr * expr
  | STitle of {
      t_title : expr;
      t_subtitle : expr option;
      t_target : expr;
      t_fade_in : int option;
      t_stay : int option;
      t_fade_out : int option;
    }
  | SClearTitle of expr
  | SActionbar of { ab_text : expr; ab_target : expr; ab_duration : int option }
  | SShowBossbar of string * expr
  | SHideBossbar of string * expr
  | SSetBossbarPart of { bp_name : string; bp_part : string; bp_value : expr; bp_target : expr }
  | SBelowname of expr * expr
  | SSetBelownameScore of expr * expr
  | SClearBelowname of expr
  | SLine of expr
  | SBlank
  | SEntry of expr * skin
  | SFill of skin
  | SPersistSet of string * expr option * expr
  (* v1.10.0 §3.2 atomic persistent op: 'add N to X' / 'subtract N from X' /
     'append V to X [for P]' / 'set X at K to V' / 'grant N X to P'. Legal in
     BOTH modes; under 'mode: standalone' it emits [pa_legacy] — the plain local
     desugaring this surface has always had — so unchanged programs stay
     byte-identical. Under 'mode: network' it emits a persist_atomic node the
     runtime routes to the backend / the owning server. *)
  | SPersistAtomic of persist_atomic
  | SGiveItem of { gi_id : expr; gi_target : expr; gi_amount : expr option }
  | SSpawnMob of { sm_target : mob_spawn_target; sm_at : expr; sm_as : string option }
  | SDespawnMob of expr
  | SSetNametag of {
      nt_part : string option; (* None = whole nametag; Some prefix|suffix|color *)
      nt_target : expr;
      nt_value : expr;
      nt_viewer : expr option; (* None = all viewers *)
    }
  | SResetNametag of { rn_target : expr; rn_viewer : expr option }
  | SSendPacket of { sp_name : string; sp_fields : (string * expr) list; sp_target : expr }
  | SCancelPacket
  (* --- phase-6 display entities --- *)
  | SShowDisplay of { sh_display : expr; sh_target : expr }
  | SHideDisplay of { hi_display : expr; hi_target : expr }
  | SMountDisplay of { mo_display : expr; mo_entity : expr }
  | STeleportDisplay of { tp_display : expr; tp_to : expr }
  | SDestroyDisplay of expr
  (* --- phase-6 http --- *)
  | SReply of { rp_code : expr option; rp_body : expr }
  (* --- phase-6 NBS songs --- *)
  | SPlaySong of {
      ps_song : expr;
      ps_target : expr option; (* 'to <target>' form *)
      ps_tick : expr option; (* optional 'at tick N' start offset *)
      ps_at : expr option; (* 'at <location> radius R' form *)
      ps_radius : expr option;
    }
  | SPauseSong of expr
  | SResumeSong of expr
  | SStopSong of expr
  | SBroadcastSong of expr
  | SSongVolume of { vo_target : expr; vo_volume : expr }
  | SFadeSong of { fa_target : expr; fa_volume : expr; fa_ticks : int }
  (* --- phase-6 blocks --- *)
  | SSetBlock of { bl_at : expr; bl_block : expr }
  | SFillBlocks of { fb_from : expr; fb_to : expr; fb_block : expr }
  (* --- phase-6 sounds --- *)
  | SPlaySound of {
      sn_sound : expr;
      sn_target : expr;
      sn_at : expr option;
      sn_volume : expr option;
      sn_pitch : expr option;
    }
  | SStopSound of { so_sound : expr option; so_target : expr }
  (* --- phase-6 particles --- *)
  | SSpawnParticle of {
      pa_particle : expr;
      pa_at : expr;
      pa_count : expr option;
      pa_offset : (expr * expr * expr) option;
      pa_speed : expr option;
      pa_viewer : expr option; (* None = all viewers *)
    }
  (* --- phase-6 MOTD --- *)
  | SSetServerMotd of expr
  (* --- phase-6 toasts --- *)
  | SShowToast of {
      to_title : expr;
      to_description : expr option;
      to_icon : expr option;
      to_frame : (string * pos) option; (* task | goal | challenge *)
      to_target : expr;
    }
  (* --- phase-6 map canvases --- *)
  | SDrawPixel of { px_canvas : expr; px_x : expr; px_y : expr; px_color : expr }
  | SDrawRect of {
      rc_canvas : expr;
      rc_x1 : expr;
      rc_y1 : expr;
      rc_x2 : expr;
      rc_y2 : expr;
      rc_color : expr;
    }
  | SDrawText of { tx_canvas : expr; tx_x : expr; tx_y : expr; tx_text : expr; tx_color : expr }
  | SGiveMap of { gm_canvas : expr; gm_target : expr }
  (* --- W-tasks: first-class per-object task registry (<obj>.tasks.<id>) --- *)
  (* set <obj>.tasks.<id> to <schedule-expr> — associate a named Schedule with
     the owner; re-assigning the same id cancels the old task first (runtime).
     tk_owner is the owning object, tk_id the task id, tk_value a Schedule. *)
  | STaskSet of { tk_owner : expr; tk_id : string; tk_value : expr }
  (* cancel <obj>.tasks.<id> / stop <obj>.tasks.<id> — cancel the named task. *)
  | STaskCancel of { tc_owner : expr; tc_id : string }
  (* place <Block|"id"> at <location> — imperative block placement. *)
  | SPlaceBlock of { pb_block : expr; pb_at : expr }
  (* remove block at <location> — set air and cancel every task bound to that
     position. *)
  | SRemoveBlock of expr
  (* --- phase-6 schedulers --- *)
  | SCancelSchedule of expr
  (* --- phase-11 scheduler v2 --- *)
  (* 'stop': cancel the enclosing schedule/repeat after the current run.
     Legal only inside an every/schedule/repeat body. *)
  | SStop
  (* 'repeat <count> times [every <dur>] { body }': run the body 'count'
     times, spaced by 'every' (default immediate/consecutive ticks). 'run'
     and 'stop' are bound inside the body; async-colored like a schedule. *)
  | SRepeat of { rp_count : expr; rp_every : int option; rp_body : stmt list }
  (* --- phase-6 worlds --- *)
  | SCreateWorld of { cw_name : expr; cw_readonly : bool; cw_loader : expr }
  | SLoadWorld of { lw_name : expr; lw_loader : expr }
  | SUnloadWorld of { uw_name : expr; uw_save : bool; uw_teleport : expr option }
  | SSaveWorld of expr
  | SCloneWorld of { cl_from : expr; cl_to : expr; cl_loader : expr }
  | SDeleteWorld of { dw_name : expr; dw_loader : expr }
  | SImportWorld of { iw_path : expr; iw_name : expr; iw_loader : expr }
  (* --- phase-7 entities --- *)
  | SSpawnEntity of { se_type : expr; se_at : expr; se_as : string option }
  | SRemoveEntity of expr
  | SMount of { m_rider : expr; m_vehicle : expr }
  | SDismount of expr
  | SLaunchProjectile of {
      lp_type : expr;
      lp_from : expr;
      lp_velocity : expr option; (* 'with velocity <vec>' *)
      lp_speed : expr option; (* 'with speed N' — look direction * speed *)
      lp_as : string option;
    }
  (* --- phase-9 dispenser runtime: 'dispense from <location>' fires the
     dispenser/dropper block at that location --- *)
  | SDispenseFrom of expr
  (* --- first-class holograms + npcs (GROUP C/D) --- *)
  (* show hologram "n" to <target>; hide hologram "n" from <target> *)
  | SShowHologram of string * expr
  | SHideHologram of string * expr
  (* set hologram "n" line <k> to <expr> *)
  | SSetHologramLine of { shl_name : string; shl_index : expr; shl_value : expr }
  (* move hologram "n" to <location> *)
  | SMoveHologram of string * expr
  | SRemoveHologram of string
  (* set npc "n" skin <form> / name <expr> / location <expr>; remove npc "n" *)
  | SSetNpcSkin of { sns_name : string; sns_skin : npc_skin }
  | SSetNpcName of { snn_name : string; snn_value : expr }
  | SSetNpcLocation of { snl_name : string; snl_value : expr }
  | SRemoveNpc of string
  (* W-viewers §2: show npc "n" to <target>; hide npc "n" from <target>. Npcs
     are name-keyed declarations (not spawn handles), so — like scoreboards /
     holograms — the viewer target routes through the SAME Viewable add/remove
     viewer mechanism as 'show <entity> to <player>' (Minestom fake players are
     Viewable). *)
  | SShowNpc of string * expr
  | SHideNpc of string * expr
  (* --- W-viewers: Minestom Viewable API on entities ---
     show <entity> to <player|list<Player>|all>   -> addViewer(s)
     hide <entity> from <player|list<Player>|all> -> removeViewer(s) *)
  | SShowEntity of { she_entity : expr; she_target : expr }
  | SHideEntity of { hie_entity : expr; hie_target : expr }
  (* set name of <entity> to <String> for <player>: per-viewer overhead name,
     sent to that one viewer only (per-viewer EntityMetadataPacket) *)
  | SSetEntityName of { sen_entity : expr; sen_value : expr; sen_viewer : expr }
  (* --- W-pvp: attribute MODIFIERS as English statements (were
     add/remove_attribute_modifier). The attribute is the ident after
     '<entity>.', validated against combat_attribute_names; the operation is one
     of add | add_multiplied_base | add_multiplied_total.
       add modifier "<id>" to <e>.<attr> of <amount> <operation>
       remove modifier "<id>" from <e>.<attr> *)
  | SAddModifier of {
      am_id : expr;
      am_entity : expr;
      am_attr : string;
      am_attr_pos : pos;
      am_amount : expr;
      am_op : string;
      am_op_pos : pos;
    }
  | SRemoveModifier of { rm_id : expr; rm_entity : expr; rm_attr : string; rm_attr_pos : pos }
  (* --- W-pvp: combat EFFECT verbs (were apply_damage/apply_knockback/
     apply_effect/remove_effect/spawn_projectile) --- *)
  (* damage <target> by <amount> [as "<damage_type>"] [from <source>] *)
  | SDamage of { dm_target : expr; dm_amount : expr; dm_type : expr option; dm_source : expr option }
  (* knock <target> away from <location> [with strength <s>] (default 0.4) *)
  | SKnock of { kn_target : expr; kn_from : expr; kn_strength : expr option }
  (* apply "<effect>" <amplifier> to <e> for <duration> *)
  | SApplyEffect of { ae_effect : expr; ae_amplifier : expr; ae_entity : expr; ae_duration : expr }
  (* remove "<effect>" from <e> *)
  | SRemoveEffect of { re_effect : expr; re_entity : expr }
  (* shoot "<projectile>" from <location> [with velocity <vec>] [by <shooter>] *)
  | SShoot of { sh_type : expr; sh_from : expr; sh_velocity : expr option; sh_shooter : expr option }
  (* --- v1.9.0 custom mob AI: navigator statements (§5) ---
     path <mob> to <Entity|Location> [at speed <n>] -> navigator.setPathTo *)
  | SPath of { pa_mob : expr; pa_to : expr; pa_speed : expr option }
  (* stop pathing <mob> -> navigator reset *)
  | SStopPathing of expr
  (* look at <Entity|Location> -> face without moving; the subject is the
     enclosing goal's bound `mob` (bound in the runtime callback) *)
  | SLookAt of expr

and gui_open = {
  go_name : string;
  go_target : expr;
  go_init : (string * expr) list;
}

(* the subject of a 'spawn mob' statement (§2 nominal custom types).
   - MSByType: 'spawn mob Ghoul' — spawn by the compile-time custom type name;
     the binding is the nominal subtype (x : Ghoul). mst_id is the resolved
     runtime id (snake_case of the name, or the decl's explicit id:); it is
     filled in by the typechecker and read at emit.
   - MSById: 'spawn mob by id <expr>' — data-driven dynamic spawn by a runtime
     string id; the binding is the base Mob. *)
and mob_spawn_target =
  | MSByType of { mst_name : string; mst_pos : pos; mutable mst_id : string }
  | MSById of expr

(* v1.10.0 §3.2 atomic persistent op. [pa_op] is the SURFACE op as written;
   [pa_kind] is refined by the typechecker from the persistent's declared value
   type ("increment" for numbers, "append" for lists, "put" for maps), so the
   runtime never has to re-derive it. [pa_legacy] is the plain local mutation
   this surface desugars to in 'mode: standalone'. *)
and persist_atomic_op =
  | PAAdd
  | PASubtract
  | PAAppend
  | PASetAt

and persist_atomic = {
  pa_op : persist_atomic_op;
  pa_name : string;
  pa_subject : expr option;
  pa_key : expr option;
  pa_value : expr;
  mutable pa_legacy : stmt;
  mutable pa_kind : string;
  pa_pos : pos;
}

type argument = {
  arg_name : string;
  arg_type : data_type;
  arg_default : string option;
  arg_pos : pos;
}

type exec_block = {
  ex_async : bool;
  ex_stmts : stmt list;
}

type command = {
  names : string list;
  permission : string option;
  description : string option;
  arguments : argument list;
  execute : exec_block option;
  cmd_pos : pos;
}

type func = {
  fn_name : string;
  fn_async : bool;
  fn_exported : bool;
  params : param list;
  body : stmt list;
  fn_pos : pos;
}

type item_spec = {
  is_material : expr option;
  is_skull : expr option;
  is_name : expr option;
  is_lore : expr list option;
  is_amount : expr option;
  is_glint : expr option;
  is_pos : pos;
}

type click_handler = {
  ch_filter : string;
  ch_body : stmt list;
}

(* first-class inline event handler on an item/mob/hologram/npc declaration
   (W-inline-handlers): on_<event> { body } — a bare handler name followed by the
   body, no parameter list. The event name is checked against the declaration
   kind's fixed handler table (registry.ml); the receiver instance and the
   event's arguments are bound as fixed bare variables (self noun + canonical arg
   names, from the registry) directly in scope — there is no `this`. Body is
   sync-colored. *)
type inline_handler = {
  ih_event : string;
  ih_body : stmt list;
  ih_pos : pos;
}

(* top-level OOP receiver declaration (design: OOP event model). A Capitalized
   base type block — `Player { on_join() {} on_death(killer) {} }` — whose
   members are fixed-name methods (reusing inline_handler: ih_event = method
   name, ih_params = user binder names, ih_body = sync-colored body). The method
   is validated against the receiver's fixed method table (registry.ml); `this`
   binds to the receiver instance type. The special `Packet { on "Class" {} }`
   block is NOT a receiver_decl — it desugars into packet_listeners. *)
type receiver_decl = {
  rc_type : string; (* "Player" | "Entity" | ... *)
  rc_type_pos : pos;
  rc_methods : inline_handler list;
  rc_pos : pos;
}

type gui_slot = {
  gs_slots : int list;
  gs_item : item_spec;
  gs_clicks : click_handler list;
  gs_refresh : int option;
  gs_pos : pos;
}

type gui_editable = {
  ge_slots : int list;
  ge_on_change : stmt list option;
  ge_pos : pos;
}

type gui_paginate = {
  gp_source : expr;
  gp_slots : int list;
  gp_render : item_spec;
  gp_on_click : stmt list option;
  gp_prev_slot : int option;
  gp_next_slot : int option;
  gp_pos : pos;
}

type fill_value =
  | FSpec of item_spec
  | FExpr of expr

type gui = {
  g_name : string;
  g_exported : bool;
  g_rows : int;
  g_title : expr;
  g_state : (string * expr) list;
  g_fill : fill_value option;
  g_border : fill_value option;
  g_slots : gui_slot list;
  g_editable : gui_editable list;
  g_paginate : gui_paginate option;
  g_refresh : int option;
  g_on_open : stmt list option;
  g_on_close : stmt list option;
  g_on_click : stmt list option;
  g_pos : pos;
}

type update_spec =
  | UTicks of int
  | UManual

type scoreboard = {
  sb_name : string;
  sb_exported : bool;
  sb_title : expr;
  sb_update : update_spec;
  sb_numbers : string;
  sb_lines : stmt list;
  sb_pos : pos;
}

type tab_column = {
  col_body : stmt list;
  col_pos : pos;
}

type tablist = {
  tl_name : string;
  tl_exported : bool;
  tl_update : update_spec;
  tl_header : expr option;
  tl_footer : expr option;
  tl_columns : tab_column list;
  tl_pos : pos;
}

type bossbar = {
  bb_name : string;
  bb_exported : bool;
  bb_text : expr;
  bb_progress : expr;
  bb_color : string;
  bb_style : string;
  bb_update : update_spec;
  bb_pos : pos;
}

(* first-class hologram declaration (GROUP D). One stack of text-display
   entities per (hologram, viewer-scope); lines use the restricted line-DSL
   (line/blank/if/loop) shared with scoreboards. h_per_viewer is computed by
   the emitter (a line interpolating a player-scoped path forces per-viewer
   render, like scoreboards). *)
type hologram = {
  h_name : string;
  h_exported : bool;
  h_location : expr;
  h_billboard : string; (* center | vertical | horizontal | fixed (default center) *)
  h_billboard_pos : pos; (* position of the billboard value, for the enum error *)
  h_scale : expr option;
  (* viewable: <Bool> (W-viewers §1) — auto-viewable at spawn; false => hidden
     until shown to a player *)
  h_viewable : bool option;
  h_update : update_spec;
  h_lines : stmt list; (* restricted DSL: line/blank/if/loop *)
  (* first-class handlers: on_click / on_line_click (W-inline-handlers) *)
  h_handlers : inline_handler list;
  h_pos : pos;
}

(* first-class npc declaration (GROUP C): a fake player entity. skin is a
   username String (Mojang-fetched) or skin(texture, signature). name +
   on_click(player)/on_left_click(player) are per-viewer / interaction hooks. *)
type npc = {
  n_name : string;
  n_exported : bool;
  n_location : expr;
  n_display_name : expr option; (* overhead name, MiniMessage, per-viewer capable *)
  n_skin : npc_skin option;
  n_look_at_players : bool; (* head tracks nearest player *)
  (* viewable: <Bool> (W-viewers §1) — auto-viewable at spawn; false => hidden
     until shown to a player *)
  n_viewable : bool option;
  n_on_click : stmt list option; (* right-click: binds bare 'npc' and 'player' *)
  n_on_left_click : stmt list option;
  (* generic handler path (reconciled with on_click/on_left_click above): used
     to surface unknown-handler errors for any other on_<name> (W-inline-handlers) *)
  n_handlers : inline_handler list;
  n_pos : pos;
}

(* v1.10.0 §1: topology is CONFIG, not a keyword. 'mode: network' turns on
   session ownership for player-keyed declarations and replication for globals;
   'standalone' (the default) is exactly today's single-server behavior. *)
type storage_mode =
  | MStandalone
  | MNetwork

(* what to do when a session hand-off cannot complete (backend down, lease stuck
   past its TTL). Default: kick with [default_handoff_message]. *)
type handoff_failure = HFKick of string

type coordinator = CoordRedis of string

let default_handoff_message = "Loading your data — reconnect in a moment"

type storage_conf = {
  st_backend : backend;
  st_flush_ticks : int;
  st_mode : storage_mode;
  st_handoff : handoff_failure;
  st_coordinator : coordinator option;
  st_pos : pos;
}

(* §1 struct declaration: a nominal record type. A field is `name: Type
   [= default]`. srf_reactive carries the §4 @EventReceiver annotation (the field
   is an event subject; handlers on it are declared in a matching reactive block
   in the struct body). *)
type struct_field = {
  srf_name : string;
  srf_type : data_type;
  srf_default : expr option;
  srf_reactive : bool;
  srf_pos : pos;
}

(* §4 reactive struct field block: `<fieldName> { <handler> { ... } ... }` inside
   a struct body. sr_field names an @EventReceiver field of the struct; the
   handler set is the FIELD TYPE's receiver vocabulary (a: Player -> Player
   handlers). Handlers are param-less; the struct's other fields + the subject
   field + the event's vars are all in scope as bare names (reusing the
   inline-handler binding machinery). *)
type struct_reactive = {
  sr_field : string;
  sr_field_pos : pos;
  sr_handlers : inline_handler list;
  sr_pos : pos;
}

(* §5 explicit versioned schema migration (v1.7.0 Batch B): a persistent-capable
   struct may declare a `migrate to N { <stmts> }` block. Inside the block the
   raw prior stored fields are readable via the `raw` map (map<String, Any>) and
   the current struct's fields are assignable as bare vars (`set name to ...`).
   sm_version is the target schema version this block upgrades TO (it runs when
   the stored version is < N, in ascending order). *)
type struct_migration = {
  sm_version : int;
  sm_body : stmt list;
  sm_pos : pos;
}

type struct_decl = {
  su_tyname : string;
  su_exported : bool;
  (* §5 current schema version (default 1). A stored row tagged with an older
     version is upgraded through the migrate blocks on load. *)
  su_schema : int;
  su_fields : struct_field list;
  su_reactive : struct_reactive list;
  su_migrations : struct_migration list;
  su_pos : pos;
}

(* v1.10.0 §4 change events: a persistent declaration may carry a trailing block
   holding exactly one change handler — `on_change { }` for a scalar value,
   `on_entry_change { }` for a Map/List value. The body is BARE CONTEXT, the same
   binding machinery receivers and reactive struct fields use: `old` / `new` /
   `caused_here`, plus the declaration's key (`player` for `for Player` /
   `for OfflinePlayer`, `key` for `for Integer` / `for String`), and for a
   collection the changed entry's `key` with Optional `old` / `new`. Handlers run
   on the tick thread, so the body is sync-coloured (an `await`/`wait` inside is
   the existing colour error). *)
type persist_change_kind =
  | PCScalar (* on_change *)
  | PCEntry (* on_entry_change *)

type persist_change = {
  pc_kind : persist_change_kind;
  pc_body : stmt list;
  pc_pos : pos;
}

type persistent_decl = {
  pd_name : string;
  pd_subject : data_type option;
  pd_type : data_type;
  pd_default : expr;
  pd_change : persist_change option;
  pd_pos : pos;
}

let persist_change_kw = function PCScalar -> "on_change" | PCEntry -> "on_entry_change"

(* the declared value is a per-ENTRY collection (on_entry_change) rather than a
   scalar (on_change) *)
let persist_is_collection (pd : persistent_decl) =
  match pd.pd_type with DList _ | DMap _ -> true | _ -> false

(* the bare name the declaration's own key binds under inside a change handler:
   `player` for a player-keyed decl, `key` for any other `for <T>` decl, and
   nothing for a global. Shared by the typechecker and the emitter so the bound
   names in the JSON are exactly the ones that typechecked. *)
let persist_subject_bind (pd : persistent_decl) =
  match pd.pd_subject with
  | None -> None
  | Some (DSimple ("PLAYER" | "Player" | "OFFLINE_PLAYER" | "OfflinePlayer")) -> Some "player"
  | Some _ -> Some "key"

(* every bare name a change handler binds, in binding order. For a collection the
   entry `key` owns the name, so an Integer/String-keyed collection exposes only
   the entry key (the decl key would collide). *)
let persist_change_binds (pd : persistent_decl) (pc : persist_change) =
  let subj = persist_subject_bind pd in
  match pc.pc_kind with
  | PCScalar -> (match subj with Some b -> [ b ] | None -> []) @ [ "old"; "new"; "caused_here" ]
  | PCEntry ->
    (match subj with Some "player" -> [ "player" ] | _ -> [])
    @ [ "key"; "old"; "new"; "caused_here" ]

(* --- phase-5 content declarations (reduced to the generic core in phase 9:
   stats{}/ability{} are gone — gameplay systems are built in userland with
   event handlers; the language keeps identity, appearance, lore, and NBT) --- *)

type item_decl = {
  (* §2 nominal custom types: the Capitalized type name (e.g. AspectOfTheEnd) is
     the compile-time handle; it_id is the stable runtime/interop string key
     (explicit 'id:' or snake_case of the type name). *)
  it_tyname : string;
  it_id : string;
  it_exported : bool;
  it_material : string option; (* XOR skull *)
  it_skull : string option;
  it_name : expr option;
  it_rarity : (string * pos) option; (* vanilla rarity component: common..epic *)
  it_glint : expr option;
  it_amount : expr option; (* default stack size on give (phase 9) *)
  it_lore : stmt list option; (* restricted DSL: line/blank/if/loop — WYSIWYG *)
  it_attributes : (string * pos * expr) list;
  (* nested NBT (phase 9): values are scalars, EList lists, or EMap compounds *)
  it_tags : (string * expr) list;
  (* on_click(left|right|any) sugar: filtered PlayerUseItem handlers for this
     item id, emitted like gui click handlers (phase 9) *)
  it_on_click : click_handler list;
  (* additive first-class handlers: on_right_click / on_left_click /
     on_right_click_block / on_attack_entity / on_consume / on_drop /
     on_pickup / on_swap_to / on_break (W-inline-handlers) *)
  it_handlers : inline_handler list;
  it_pos : pos;
}

type mob_drop = {
  dr_id : string;
  dr_pos : pos;
  dr_chance : expr;
  dr_amount : expr option;
}

(* a typed mob tag block entry (W-viewers §2): a field is either a TYPE
   declaration (`hits: map<Player, Integer>` -> a typed, indexable tag store)
   or an item-style value init (`level: 5` -> type inferred from the value).
   Typed tags hold LIVE in-memory values on the entity (a real map/list object),
   no NBT serialization needed. Undeclared keys still work as freeform
   optional<Any> entity tags via mob.tags.<anykey>. *)
type mob_tag_spec =
  | MTType of data_type
  | MTValue of expr

type mob_tag = {
  mt_name : string;
  mt_pos : pos;
  mt_spec : mob_tag_spec;
}

(* --- v1.9.0 custom mob AI (§2-4) ---

   A goal's lifecycle: the five GoalSelector hooks. should_start / should_end are
   Boolean expressions (default true / false); on_start / on_tick / on_end are
   statement bodies. All optional. The bodies run on the TICK thread each tick, so
   the checker sync-colors them (await/wait forbidden). Bare context binds `mob`
   (the creature) and `target` (Optional<Entity>, the group's selected target). *)
type goal_lifecycle = {
  gl_should_start : expr option;
  gl_on_start : stmt list option;
  gl_on_tick : stmt list option;
  gl_should_end : expr option;
  gl_on_end : stmt list option;
}

(* the natural-language target selectors (§4). Each produces a Minestom
   TargetSelector; `at_range` is the `within <n>` search radius. *)
type ai_target_kind =
  | ATPlayer (* closest Player *)
  | ATHostile (* closest hostile *)
  | ATLastAttacker (* last attacker (LastEntityDamagerTarget) *)
  | ATMobType of string (* closest <MobType> (a declared custom mob type) *)

type ai_target =
  | ATNatural of { at_kind : ai_target_kind; at_range : expr; at_pos : pos }
  (* custom selection block: `target { <stmts> return <Entity|Optional<Entity>|none> }`
     -> a TargetSelector.findTarget(); `mob` bound *)
  | ATBlock of { at_body : stmt list; at_pos : pos }

(* inline goal inside an `ai { }` block: `goal "<name>" [priority N] { ... }`.
   Priority: declaration order is the default (first = highest); `priority N`
   overrides (lower N = higher priority). *)
type ai_goal = {
  ag_name : string;
  ag_priority : int option;
  ag_life : goal_lifecycle;
  ag_pos : pos;
}

(* a reference to a reusable named goal type from `goals: [ Chase priority 1, Wander ]` *)
type goal_ref = {
  gr_name : string;
  gr_priority : int option;
  gr_pos : pos;
}

(* one `ai { }` block on a mob = one EntityAIGroup: target selector(s) + inline
   goals + references to reusable named goal types. Coexists with the preset
   `ai: "melee"/"passive"/none` string field (mb_ai). *)
type ai_block = {
  aib_targets : ai_target list;
  aib_goals : ai_goal list;
  aib_goal_refs : goal_ref list;
  aib_pos : pos;
}

type mob_decl = {
  (* §2 nominal custom types: the Capitalized type name (e.g. Ghoul) is the
     compile-time handle; mb_id is the stable runtime/interop string key
     (explicit 'id:' or snake_case of the type name). mb_type stays the
     Minestom entity-type string, unchanged. *)
  mb_tyname : string;
  mb_id : string;
  mb_exported : bool;
  mb_type : (string * pos) option; (* required; checked against EntityType names *)
  mb_name : expr option;
  mb_health : expr option;
  mb_damage : expr option;
  mb_speed : expr option;
  mb_ai : (string * pos) option; (* melee | passive | none *)
  (* v1.9.0 custom mob AI: the `ai { }` block (targets + goals), if present.
     Coexists with the preset `mb_ai` string form. *)
  mb_ai_block : ai_block option;
  (* viewable: <Bool> (W-viewers §1) — setAutoViewable at spawn. false =>
     the mob is hidden until explicitly shown with 'show <mob> to <player>' *)
  mb_viewable : bool option;
  (* typed tag block (W-viewers §2): mob.tags.<name> gets the declared type *)
  mb_tags : mob_tag list;
  mb_drops : mob_drop list;
  mb_on_spawn : stmt list option;
  mb_on_death : stmt list option;
  mb_on_attack : stmt list option;
  (* on_hit { }: fired when this mob is damaged; binds the bare 'mob' and
     'attacker' (optional<Player>) variables in scope (no parameter list). *)
  mb_on_hit : stmt list option;
  (* additive first-class handlers: on_click / on_attack / on_target / on_tick
     (on_spawn/on_death/on_hit keep their dedicated fields above)
     (W-inline-handlers) *)
  mb_handlers : inline_handler list;
  mb_pos : pos;
}

(* v1.9.0 reusable named goal TYPE (§3): a top-level `goal Chase { <lifecycle> }`
   (PascalCase, like a struct). Attached to mobs via `goals: [ Chase, ... ]`; when
   run, `mob` binds to whatever creature it is attached to. *)
type goal_type_decl = {
  gt_name : string;
  gt_life : goal_lifecycle;
  gt_pos : pos;
}

type packet_listener = {
  pk_name : string;
  pk_execute : exec_block option;
  pk_pos : pos;
}

(* --- W-blocks: block handlers + placement rules (top-level decls) ---

   A callback of a block_handler / placement_rule: a fixed-name hook whose user
   binder names bind positionally to the hook's fixed parameter types (defined
   in registry.ml). cb_ret carries the optional written '-> Type' annotation;
   the semantic return type is fixed by the hook name and validated by the
   checker. *)
type block_cb = {
  cb_name : string;
  cb_params : (string * pos) list;
  cb_ret : data_type option;
  cb_body : stmt list;
  cb_pos : pos;
}

(* block_handler "id" { on_place(...) on_destroy(...) on_interact(...)->Boolean
   on_touch(...) tick(...) } — routes BlockHandler callbacks through the runtime
   for blocks of that id. *)
type block_handler_decl = {
  bh_id : string;
  bh_callbacks : block_cb list;
  bh_pos : pos;
}

(* placement_rule for "id" { on_place(...)->Block on_update(...)->Block
   self_replaceable: Bool } — one BlockPlacementRule per block family. *)
type placement_rule_decl = {
  pr_id : string;
  pr_callbacks : block_cb list;
  pr_self_replaceable : bool;
  pr_pos : pos;
}

(* --- phase-8 fishing loot tables --- *)

(* one 'catch item|mob "id" weight N [message "..."]' row of a fishing_loot
   table; weight is a declaration constant (folded like mob drop chances) *)
type fishing_catch = {
  fc_mob : bool; (* false = item catch, true = mob catch *)
  fc_id : string;
  fc_weight : expr;
  fc_message : string option;
  fc_pos : pos;
}

(* fishing_loot "name" { medium: water|lava, world: "...", catch ... } —
   matched at runtime by medium + optional world name; weighted rows *)
type fishing_loot = {
  fl_name : string;
  fl_medium : (string * pos) option; (* required; validated water | lava *)
  fl_world : string option;
  fl_catches : fishing_catch list;
  fl_pos : pos;
}

type auth =
  | AuthOffline
  | AuthMojang
  | AuthVelocity of string
  | AuthBungeecord

(* server{} http { port, bind } — the JDK-httpserver API endpoint (design 6B) *)
type http_conf = {
  hc_port : int;
  hc_bind : string;
}

(* server{} fishing { min_bite, max_bite } — the randomized bite window of the
   native fishing engine, in ticks (phase 8) *)
type fishing_conf = {
  fi_min_bite : int;
  fi_max_bite : int;
}

type server_conf = {
  sv_auth : auth;
  sv_host : string option;
  sv_port : int option;
  sv_brand : string option;
  sv_motd : string option;
  sv_http : http_conf option;
  sv_fishing : fishing_conf option; (* bite window of the fishing engine (phase 8) *)
  sv_favicon : string option; (* png path, base64'd at boot (design 6D) *)
  sv_permissions : (string * string list) list; (* user -> permission list *)
  sv_open_to_lan : bool;
  sv_lighting : bool; (* whether world lighting is computed/sent (default true) *)
  sv_pos : pos;
}

(* api "/path/:param" { method: GET, execute { ... } } — handlers are
   async-colored by default (they run off-thread on virtual threads) *)
type api_decl = {
  api_path : string;
  api_method : (string * pos) option; (* GET|POST|PUT|DELETE|ANY; None = ANY *)
  api_execute : exec_block option;
  api_pos : pos;
}

(* top-level 'every <duration> { body }' — async-colored, starts at boot *)
type sched_decl = {
  sd_every : int; (* ticks *)
  sd_name : string option; (* 'every <dur> as "name"' — named registry entry *)
  sd_body : stmt list;
  sd_pos : pos;
}

(* --- phase-6 module system --- *)

(* import "name" (script dir, then the addon search path) or
   import "./relative.sw" (relative to the importing file) *)
type import_decl = {
  im_spec : string;
  im_pos : pos;
}

(* module-level 'var name = expr': private module state, typed by inference
   from the initializer, non-persistent, initialized at load in dependency
   order *)
type module_var = {
  mv_name : string;
  mv_value : expr;
  mv_pos : pos;
}

type script = {
  imports : import_decl list;
  module_vars : module_var list;
  commands : command list;
  functions : func list;
  guis : gui list;
  scoreboards : scoreboard list;
  tablists : tablist list;
  bossbars : bossbar list;
  holograms : hologram list;
  npcs : npc list;
  servers : server_conf list;
  storages : storage_conf list;
  persistents : persistent_decl list;
  structs : struct_decl list;
  items : item_decl list;
  mobs : mob_decl list;
  goal_types : goal_type_decl list;
  packet_listeners : packet_listener list;
  apis : api_decl list;
  schedulers : sched_decl list;
  fishing_loots : fishing_loot list;
  block_handlers : block_handler_decl list;
  placement_rules : placement_rule_decl list;
  receivers : receiver_decl list;
}

(* Constant-fold a numeric declaration-field expression (mob health/damage/
   speed, drop chance/amount, item attributes/amount): number literals, unary
   minus, and + - * / % over folded operands. Anything else - variables,
   properties, calls - is not a declaration constant and yields None. The
   Java loader only accepts literal scalars for these fields, so the checker
   requires foldability and the emitter serializes the folded literal. *)
let rec fold_number (e : expr) : float option =
  match e.e with
  | ENumber { value; _ } -> float_of_string_opt value
  | EUnary ("NEGATE", operand) -> Option.map (fun f -> -.f) (fold_number operand)
  | EBinary (op, left, right) -> (
    match (fold_number left, fold_number right) with
    | Some a, Some b -> (
      match op with
      | "ADD" -> Some (a +. b)
      | "SUBTRACT" -> Some (a -. b)
      | "MULTIPLY" -> Some (a *. b)
      | "DIVIDE" -> if b = 0.0 then None else Some (a /. b)
      | "MODULO" -> if b = 0.0 then None else Some (Float.rem a b)
      | _ -> None)
    | _ -> None)
  | _ -> None
