open Ast
open Registry
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
    net_mode = false;
    atomic_legacy_of = None;
    awaiting_operand = false;
    item_ids = Hashtbl.create 16;
    mob_ids = Hashtbl.create 16;
    custom_mobs = Hashtbl.create 16;
    custom_items = Hashtbl.create 16;
    goal_types = Hashtbl.create 8;
    structs = Hashtbl.create 16;
    scoreboards = Hashtbl.create 8;
    tablists = Hashtbl.create 8;
    bossbars = Hashtbl.create 8;
    holograms = Hashtbl.create 8;
    npcs = Hashtbl.create 8;
    guis = Hashtbl.create 8;
    schedules = Hashtbl.create 8;
    mod_vars = Hashtbl.create 8;
    import_privates = Hashtbl.create 8;
    cur_mob_tags = [];
    cur_packet_fields = None;
  }

(* Collect every named-schedule name declared in a script: top-level
   'every ... as "name"' plus inline 'schedule ... as "name"' expressions
   anywhere in a handler/function/initializer body. These feed the string-form
   'cancel schedule "name"' / is_running("name") reference checks; missing one
   would false-positive a valid program, so the walk covers every body that can
   host statements — which is exactly what {!Walk.iter_script} guarantees. *)
let collect_sched_names (script : Ast.script) : string list =
  let names = ref [] in
  let add = function Some n -> names := n :: !names | None -> () in
  List.iter (fun (sd : sched_decl) -> add sd.sd_name) script.schedulers;
  Walk.iter_script
    ~on_expr:(fun (e : Ast.expr) ->
      match e.e with
      | ESchedule { sc_name; _ } -> add sc_name
      | _ -> ())
    ~on_stmt:(fun _ -> ())
    script;
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
      (* v1.9.0: reusable named goal types are unit-global, referenced by
         `goals: [ Name ]` on any mob in the unit *)
      List.iter
        (fun (gt : goal_type_decl) -> Hashtbl.replace ctx.goal_types gt.gt_name ())
        s.goal_types;
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
                  (p.p_name, match p.p_type with Some dt -> resolve_ty ctx dt | None -> TAny))
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
    | EMethod (recv, _, args) ->
      walk recv;
      List.iter walk args
    | EBinary (_, a, b) ->
      walk a;
      walk b
    | EUnary (_, a) -> walk a
    | EList items -> List.iter walk items
    | EProp (target, _) -> walk target
    | ETaskRunning { tr_owner; _ } -> walk tr_owner
    | EPersistGet (_, subject) -> Option.iter walk subject
    | EMap fields -> List.iter (fun (_, v) -> walk v) fields
    | EMapLit entries -> List.iter (fun (_, v) -> walk v) entries
    | EStructNew (_, fields) -> List.iter (fun (_, v) -> walk v) fields
    | EFutureSpawn (name, args) ->
      if Hashtbl.mem own_fns name then
        err ctx e.epos
          "module variable '%s' spawns the function '%s' in its initializer — functions can read \
           module variables that are not initialized yet at this point; inline the value or \
           reorder the declarations"
          mv.mv_name name;
      List.iter walk args
    | EAwait future -> walk future
    | EAllOf futures | EAnyOf futures -> walk futures
    | ELambda _ | ESchedule _ | EAsyncExpr _ ->
      () (* deferred bodies run after initialization *)
    | EString _ | ENumber _ | EBool _ | ENone | EVar _ | EType _ | EAllPlayers
    | ELoaderStorage _ ->
      ()
  in
  walk mv.mv_value

(* Module-level 'var name = expr' declarations: typed by inference from the
   initializer (checked in declaration order, so later initializers see
   earlier vars), private to the module, non-persistent. *)
let check_module_vars ctx (script : Ast.script) =
  let bctx = { color = Sync; event = None; args = None; ret_sink = None; packet = false; api = false; in_schedule = false; override = None } in
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
  List.iter (check_struct_decl ctx) script.structs;
  List.iter (check_persistent ctx) script.persistents;
  check_storages ctx script.storages;
  List.iter (check_function ctx) script.functions;
  List.iter (check_command ctx) script.commands;
  List.iter (check_gui ctx) script.guis;
  List.iter (check_scoreboard ctx) script.scoreboards;
  List.iter (check_tablist ctx) script.tablists;
  List.iter (check_bossbar ctx) script.bossbars;
  check_holograms ctx script.holograms;
  check_npcs ctx script.npcs;
  List.iter (check_item_decl ctx) script.items;
  List.iter (check_mob_decl ctx) script.mobs;
  check_goal_types ctx script.goal_types;
  List.iter (check_packet_listener ctx) script.packet_listeners;
  List.iter (check_api_decl ctx) script.apis;
  List.iter (check_sched_decl ctx) script.schedulers;
  check_fishing_loots ctx script.fishing_loots;
  check_block_handlers ctx script.block_handlers;
  check_placement_rules ctx script.placement_rules;
  check_receivers ctx script.receivers;
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
        (* §1/§2: custom type names (mobs/items) and struct names must be
           visible before any type annotation (function params, persistents,
           struct fields, mob tags) is resolved. Register every type NAME first,
           then resolve struct field types (which may reference other structs). *)
        register_struct_names ctx tm.tm_script;
        register_custom_types ctx tm.tm_script;
        register_struct_fields ctx tm.tm_script;
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
        List.iter (fun (sd : struct_decl) -> claim ms "struct" sd.su_tyname sd.su_pos) s.structs;
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
          s.persistents;
        List.iter
          (fun (bh : block_handler_decl) ->
            claim ms "block_handler" (normalize_block_id bh.bh_id) bh.bh_pos)
          s.block_handlers;
        List.iter
          (fun (pr : placement_rule_decl) ->
            claim ms "placement_rule" (normalize_block_id pr.pr_id) pr.pr_pos)
          s.placement_rules)
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
              dep.ms_input.tm_script.mobs;
            (* exported custom type names become visible for nominal use in the
               importer (type positions, 'is a', 'spawn mob Ghoul') *)
            List.iter
              (fun mb ->
                if mb.mb_exported && not (Hashtbl.mem ctx.custom_mobs mb.mb_tyname) then
                  Hashtbl.replace ctx.custom_mobs mb.mb_tyname mb.mb_id)
              dep.ms_input.tm_script.mobs;
            List.iter
              (fun it ->
                if it.it_exported && not (Hashtbl.mem ctx.custom_items it.it_tyname) then
                  Hashtbl.replace ctx.custom_items it.it_tyname it.it_id)
              dep.ms_input.tm_script.items;
            (* exported struct types become visible for nominal use in the
               importer (type positions, construction, 'is a') *)
            List.iter
              (fun (sd : struct_decl) ->
                if sd.su_exported && not (Hashtbl.mem ctx.structs sd.su_tyname) then
                  match Hashtbl.find_opt dep.ms_ctx.structs sd.su_tyname with
                  | Some si -> Hashtbl.replace ctx.structs sd.su_tyname si
                  | None -> ())
              dep.ms_input.tm_script.structs)
        ms.ms_input.tm_imports)
    states;

  (* v1.10.0 §1: the storage topology is unit-wide — one runtime PersistStore
     serves every module — so a 'mode: network' block anywhere turns the network
     typing rules on for the whole compilation unit. *)
  let net =
    List.exists
      (fun ms ->
        List.exists
          (fun (sc : storage_conf) -> sc.st_mode = MNetwork)
          ms.ms_input.tm_script.storages)
      states
  in
  List.iter (fun ms -> ms.ms_ctx.net_mode <- net) states;

  (* --- pass 2: per-module checks in dependency order, so imported return
     types are refined before their callers are checked --- *)
  List.iter
    (fun ms ->
      check_module_vars ms.ms_ctx ms.ms_input.tm_script;
      check_module_body ms.ms_ctx ms.ms_input.tm_script)
    states;

  (* v1.10.0 §5 layer 2: the change-handler write graph is UNIT-wide — a handler
     in one module can write a persistent declared in another — so it runs once,
     after every module's bodies are checked. Each module contributes the function
     lookup it actually sees (its own functions plus the exported functions of its
     direct imports), so an interprocedural write is followed the way the program
     resolves the call. *)
  let fn_view ms =
    let own = Hashtbl.create 16 in
    List.iter
      (fun (f : func) -> Hashtbl.replace own f.fn_name f)
      ms.ms_input.tm_script.functions;
    List.iter
      (fun imported ->
        match Hashtbl.find_opt by_name imported with
        | None -> ()
        | Some dep ->
          List.iter
            (fun (f : func) ->
              if f.fn_exported && not (Hashtbl.mem own f.fn_name) then
                Hashtbl.replace own f.fn_name f)
            dep.ms_input.tm_script.functions)
      ms.ms_input.tm_imports;
    fun n -> Hashtbl.find_opt own n
  in
  Tc_cycles.check
    (List.map (fun ms -> (ms.ms_ctx, ms.ms_input.tm_script, fn_view ms)) states);

  dedupe (List.concat_map (fun ms -> List.rev ms.ms_ctx.errors) states)

let run ~file (script : Ast.script) : Diagnostics.error list =
  run_all
    [ { tm_name = "main"; tm_file = file; tm_imports = []; tm_script = script } ]
