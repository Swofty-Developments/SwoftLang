package net.swofty;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import net.swofty.compiler.ParsedScript;
import net.swofty.gui.GuiRuntime;
import net.swofty.items.ItemInteractRuntime;
import net.swofty.items.ItemAttributeTask;
import net.swofty.items.ItemRegistry;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.MobRuntime;
import net.swofty.model.BossbarModel;
import net.swofty.model.GuiModel;
import net.swofty.model.ItemDefModel;
import net.swofty.model.MobDefModel;
import net.swofty.model.PacketHandlerModel;
import net.swofty.model.PersistentDeclModel;
import net.swofty.model.ScoreboardModel;
import net.swofty.model.ServerConfigModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.model.TablistModel;
import net.swofty.nametags.NametagRuntime;
import net.swofty.packets.PacketListeners;
import net.swofty.persist.PersistStore;
import net.swofty.processors.CommandProcessor;
import net.swofty.processors.EventProcessor;
import net.swofty.ui.UiRuntime;

/**
 * Main entry point for the SwoftLang scripting engine
 * Coordinates script loading and processing
 */
public class SwoftLangEngine {
    private final ScriptLoader scriptLoader;
    private final CommandProcessor commandProcessor;
    private final EventProcessor eventProcessor;
    private final List<GuiModel> guis = new ArrayList<>();
    private final List<ScoreboardModel> scoreboards = new ArrayList<>();
    private final List<TablistModel> tablists = new ArrayList<>();
    private final List<BossbarModel> bossbars = new ArrayList<>();
    private final List<PersistentDeclModel> persistents = new ArrayList<>();
    private final List<ItemDefModel> items = new ArrayList<>();
    private final List<MobDefModel> mobs = new ArrayList<>();
    private final List<PacketHandlerModel> packetHandlers = new ArrayList<>();
    private final List<net.swofty.model.ApiHandlerModel> apis = new ArrayList<>();
    private final List<net.swofty.model.EveryDeclModel> everyDecls = new ArrayList<>();
    private final List<net.swofty.model.FishingLootModel> fishingLoot = new ArrayList<>();
    private final List<net.swofty.model.HologramModel> holograms = new ArrayList<>();
    private final List<net.swofty.model.NpcModel> npcs = new ArrayList<>();
    private final List<net.swofty.model.BlockHandlerModel> blockHandlers = new ArrayList<>();
    private final List<net.swofty.model.PlacementRuleModel> placementRules = new ArrayList<>();
    private final List<net.swofty.model.StructDefModel> structs = new ArrayList<>();
    private final List<net.swofty.mobs.ai.GoalTypeModel> goalTypes = new ArrayList<>();
    private ServerConfigModel serverConfig;
    private StorageConfigModel storageConfig;

    /**
     * Initialize the SwoftLang engine with default settings
     */
    public SwoftLangEngine() {
        this("scripts", "sw");
    }

    /**
     * Initialize the SwoftLang engine with custom settings
     * @param scriptsDirectory Directory to search for script files
     * @param fileExtension File extension for script files
     */
    public SwoftLangEngine(String scriptsDirectory, String fileExtension) {
        this.scriptLoader = new ScriptLoader(scriptsDirectory, fileExtension);
        this.commandProcessor = new CommandProcessor(scriptLoader);
        this.eventProcessor = new EventProcessor(scriptLoader);
    }

    /**
     * Initialize the engine by scanning and processing all scripts
     */
    public void initialize() {
        System.out.println("Initializing SwoftLang Engine...");

        // Scan for script files
        List<File> files = scriptLoader.scanScripts();
        System.out.println("Found " + files.size() + " script files");

       // Process commands
       int commandCount = commandProcessor.processCommands();
       System.out.println("Processed " + commandCount + " commands");

       // Process events
       int eventCount = eventProcessor.processEvents();
       System.out.println("Processed " + eventCount + " events");

       collectDeclarations();
       initializePersistence();
    }

    /**
     * Wire the PersistStore from the storage { } block; scripts without one
     * fall back to the default files backend. Nothing is initialized when
     * no script declares persistent variables or a storage block.
     */
    private void initializePersistence() {
        // the seen-players store always rides the configured backend (or
        // the default files backend) so offline players work everywhere
        net.swofty.players.SeenPlayersStore.initialize(storageConfig);
        if (persistents.isEmpty() && storageConfig == null) {
            return;
        }
        PersistStore.initialize(persistents, storageConfig);
    }

    /**
     * Flush persistent variables and release the storage backend, stop
     * the http server, songs, script displays, script-spawned entities
     * and projectiles, and loaded worlds
     */
    public void shutdown() {
        // Dismantle every live program-derived subsystem through the SAME
        // central teardown the hot reload uses (#58) — no more hand-maintained
        // duplicate of the per-subsystem teardown list that could drift from
        // register(). Then release the persistent/session/world state that a
        // reload deliberately keeps but a full shutdown must flush/unload.
        net.swofty.reload.ReloadRegistry.runTeardown();
        net.swofty.worlds.WorldsRuntime.unloadAll();
        net.swofty.players.SeenPlayersStore.shutdownActive();
        PersistStore.shutdownActive();
    }

    /**
     * Gui/scoreboard/tablist/bossbar declarations and the server block;
     * at most one server block across all scripts (extras error + ignore)
     */
    private void collectDeclarations() {
        // reload wipes every live schedule (named AND anonymous, cancelling
        // any that are running) so the fresh script's every/schedule/repeat
        // declarations start clean with freshly-stamped line numbers
        net.swofty.sched.ScheduleRegistry.cancelAll();
        guis.clear();
        scoreboards.clear();
        tablists.clear();
        bossbars.clear();
        persistents.clear();
        items.clear();
        mobs.clear();
        packetHandlers.clear();
        apis.clear();
        everyDecls.clear();
        fishingLoot.clear();
        holograms.clear();
        npcs.clear();
        blockHandlers.clear();
        placementRules.clear();
        structs.clear();
        goalTypes.clear();
        serverConfig = null;
        storageConfig = null;

        for (File scriptFile : scriptLoader.getScriptFiles()) {
            try {
                ParsedScript parsed = scriptLoader.parseScript(scriptFile);
                guis.addAll(parsed.guis());
                scoreboards.addAll(parsed.scoreboards());
                tablists.addAll(parsed.tablists());
                bossbars.addAll(parsed.bossbars());
                persistents.addAll(parsed.persistents());
                items.addAll(parsed.items());
                mobs.addAll(parsed.mobs());
                packetHandlers.addAll(parsed.packetHandlers());
                apis.addAll(parsed.apis());
                everyDecls.addAll(parsed.everyDecls());
                fishingLoot.addAll(parsed.fishingLoot());
                holograms.addAll(parsed.holograms());
                npcs.addAll(parsed.npcs());
                blockHandlers.addAll(parsed.blockHandlers());
                placementRules.addAll(parsed.placementRules());
                structs.addAll(parsed.structs());
                goalTypes.addAll(parsed.goalTypes());
                if (parsed.server() != null) {
                    if (serverConfig != null) {
                        System.err.println("Error: duplicate server block in "
                                + scriptFile.getName() + " - ignoring it");
                    } else {
                        serverConfig = parsed.server();
                    }
                }
                if (parsed.storage() != null) {
                    if (storageConfig != null) {
                        System.err.println("Error: duplicate storage block in "
                                + scriptFile.getName() + " - ignoring it");
                    } else {
                        storageConfig = parsed.storage();
                    }
                }
            } catch (Exception e) {
                System.err.println("Error parsing script file: " + scriptFile.getName());
                e.printStackTrace();
            }
        }
        // §1 struct declarations must be registered before persistence
        // initializes (initializePersistence runs right after this), so a
        // persistent struct can resolve its field types for serialization.
        net.swofty.structs.StructRegistry.clear();
        for (net.swofty.model.StructDefModel struct : structs) {
            net.swofty.structs.StructRegistry.register(struct);
        }
        System.out.println("Processed " + guis.size() + " guis, " + scoreboards.size()
                + " scoreboards, " + tablists.size() + " tablists, " + bossbars.size()
                + " bossbars, " + persistents.size() + " persistents, " + items.size()
                + " items, " + mobs.size() + " mobs, " + packetHandlers.size()
                + " packet handlers, " + structs.size() + " structs");
    }

    /**
     * Register all components with their respective systems
     */
    public void register() {
        // Register commands
        commandProcessor.register();

        // Register events
        eventProcessor.registerEvents();
        // §4 struct-instance receivers: registered AFTER the global receivers so
        // their listeners are appended after (global -> struct-instance order),
        // then the liveness index is derived from the loaded persistent roots.
        eventProcessor.getEventRegistrar().registerStructReceivers(structs);

        // Wire the gui/ui runtimes and hand them the declarations. On reload,
        // cancel the previous auto-refresh tasks first so scoreboards/tablists/
        // bossbars don't accumulate stale-model tasks tracing OLD line numbers
        // (no-op on first startup; live viewers are preserved either way).
        GuiRuntime.init();
        // drop stale gui models + force-close open sessions (cancelling their
        // render timers) from a previous load before re-registering, so a
        // removed/renamed gui leaves no ghost definition and no leaked timer.
        GuiRuntime.teardown();
        UiRuntime.init();
        UiRuntime.clearTasks();
        for (GuiModel gui : guis) {
            GuiRuntime.register(gui);
        }
        for (ScoreboardModel scoreboard : scoreboards) {
            UiRuntime.register(scoreboard);
        }
        for (TablistModel tablist : tablists) {
            UiRuntime.register(tablist);
        }
        for (BossbarModel bossbar : bossbars) {
            UiRuntime.register(bossbar);
        }

        // First-class holograms + npcs (GROUP C/D): tear down any live entities
        // and tasks from a previous load, wire the disconnect/interact
        // listeners once, then (re)register the declared set.
        net.swofty.holograms.HologramRuntime.init();
        net.swofty.holograms.HologramRuntime.teardown();
        for (net.swofty.model.HologramModel hologram : holograms) {
            net.swofty.holograms.HologramRuntime.register(hologram);
        }
        net.swofty.npcs.NpcRuntime.init();
        net.swofty.npcs.NpcRuntime.teardown();
        for (net.swofty.model.NpcModel npc : npcs) {
            net.swofty.npcs.NpcRuntime.register(npc);
        }
        if (!holograms.isEmpty() || !npcs.isEmpty()) {
            System.out.println("Registered " + holograms.size() + " hologram(s) and "
                    + npcs.size() + " npc(s)");
        }

        // Phase-5 content systems: registries first, then live listeners/tasks
        ItemRegistry.clear();
        for (ItemDefModel item : items) {
            ItemRegistry.register(item);
        }
        // v1.9.0 reusable goal TYPES must be registered BEFORE the mobs so a
        // mob's `goals: [Chase]` reference resolves its lifecycle at spawn/bind.
        net.swofty.mobs.ai.GoalTypeRegistry.clear();
        for (net.swofty.mobs.ai.GoalTypeModel goalType : goalTypes) {
            net.swofty.mobs.ai.GoalTypeRegistry.register(goalType.name(), goalType.lifecycle());
        }
        MobRegistry.clear();
        for (MobDefModel mob : mobs) {
            MobRegistry.register(mob);
        }
        PacketListeners.clear();
        for (PacketHandlerModel handler : packetHandlers) {
            PacketListeners.register(handler);
        }
        ItemInteractRuntime.init();
        ItemAttributeTask.init();
        MobRuntime.init();
        // one filtered dispatcher per (kind,event) for the additive first-class
        // inline handler set (W-inline-handlers); stateless global listeners,
        // idempotent init, retargeted on reload via the live registries
        net.swofty.handlers.InlineHandlerRuntime.init();
        net.swofty.entities.ProjectileRuntime.init();
        // W-pvp per-entity in-memory state store: wire the despawn/disconnect
        // auto-clear listeners once (idempotent), then wipe every entity's
        // scratch state so the freshly (re)loaded script starts from empty.
        net.swofty.entities.EntityStateStore.init();
        net.swofty.entities.EntityStateStore.clearAll();
        // W-tasks: per-object task registry (<obj>.tasks.<id>). Wire the
        // despawn/disconnect/block-change auto-cancel listeners once
        // (idempotent), then cancel + drop every task so the reloaded script
        // starts with no owner holding a stale schedule.
        net.swofty.tasks.TaskRegistry.init();
        net.swofty.tasks.TaskRegistry.clearAll();
        // W-pvp native trackers Minestom lacks (i-frame timer + fall distance):
        // wire the damage/tick/auto-clear listeners once (idempotent), then wipe
        // every entity's tracker state so the (re)loaded script starts clean.
        net.swofty.entities.EntityCombatTrackers.init();
        net.swofty.entities.EntityCombatTrackers.clearAll();
        NametagRuntime.init();
        net.swofty.entities.EntityNametagRuntime.init();
        // dispenser block-entities: wipe stale inventories/state each reload
        net.swofty.blocks.DispenserRuntime.reset();
        net.swofty.blocks.DispenserRuntime.init();

        // W-blocks: first-class block_handler / placement_rule declarations.
        // Teardown clears the live model maps (making any handler/rule already
        // attached to placed blocks inert), then re-register the declared set;
        // init installs the one-time place listener.
        net.swofty.blocks.BlockHandlerRuntime.teardown();
        net.swofty.blocks.PlacementRuleRuntime.teardown();
        net.swofty.blocks.BlockHandlerRuntime.init();
        net.swofty.blocks.PlacementRuleRuntime.init();
        for (net.swofty.model.BlockHandlerModel handler : blockHandlers) {
            net.swofty.blocks.BlockHandlerRuntime.register(handler);
        }
        for (net.swofty.model.PlacementRuleModel rule : placementRules) {
            net.swofty.blocks.PlacementRuleRuntime.register(rule);
        }
        if (!blockHandlers.isEmpty() || !placementRules.isEmpty()) {
            System.out.println("Registered " + blockHandlers.size() + " block handler(s) and "
                    + placementRules.size() + " placement rule(s)");
        }

        registerPhase6();
        registerPhase8();

        // #58: arm the central teardown registry for the NEXT reload. Every
        // subsystem wired above registers a teardown callback here in wire
        // order; reload()/shutdown() run them in reverse (LIFO) so live state is
        // dismantled last-created-first before the new program is installed.
        registerReloadHooks();
    }

    /**
     * Register one teardown callback per live subsystem with the central
     * {@link net.swofty.reload.ReloadRegistry}, in the same order the
     * subsystems are wired in {@link #register()}. The registry runs them in
     * reverse on the next reload (schedulers/tasks first, commands last), then
     * re-registration re-arms this set. The PersistStore, seen-players store and
     * loaded worlds are intentionally excluded — persistent/session/world state
     * survives a reload and the reactive-instance liveness is re-derived from
     * the surviving persistent roots by {@code registerStructReceivers}.
     */
    private void registerReloadHooks() {
        net.swofty.reload.ReloadRegistry.clear();

        // commands (torn down last on reload — reverse order)
        net.swofty.reload.ReloadRegistry.register("commands", () -> {
            var cm = net.minestom.server.MinecraftServer.getCommandManager();
            for (String name : new ArrayList<>(commandProcessor.getCommandMap().keySet())) {
                var existing = cm.getCommand(name);
                if (existing != null) {
                    cm.unregister(existing);
                }
            }
        });
        // event/receiver listeners + reactive-instance registry + subject->
        // instance index + receiver-base index (all inside EventRegistrar.reset)
        net.swofty.reload.ReloadRegistry.register("event-listeners+reactive-instances",
                () -> eventProcessor.getEventRegistrar().reset());
        // scoreboards / tablists / bossbars auto-refresh tasks (HUD viewers)
        net.swofty.reload.ReloadRegistry.register("ui-hud-tasks",
                net.swofty.ui.UiRuntime::clearTasks);
        // open gui sessions (cancel their render timers, close inventories) +
        // registered gui models (drop removed/renamed ghosts)
        net.swofty.reload.ReloadRegistry.register("guis",
                net.swofty.gui.GuiRuntime::teardown);
        // holograms + npcs (despawn live entities, cancel their tasks)
        net.swofty.reload.ReloadRegistry.register("holograms",
                net.swofty.holograms.HologramRuntime::teardown);
        net.swofty.reload.ReloadRegistry.register("npcs",
                net.swofty.npcs.NpcRuntime::teardown);
        // custom item + mob specialization registries (MobRegistry despawns live mobs)
        net.swofty.reload.ReloadRegistry.register("item-registry",
                net.swofty.items.ItemRegistry::clear);
        net.swofty.reload.ReloadRegistry.register("mob-registry",
                net.swofty.mobs.MobRegistry::clear);
        // v1.9.0 scripted goal TYPES: clear the reusable-lifecycle registry so no
        // ghost goal survives a reload (live mobs' scripted GoalSelectors die with
        // the entities MobRegistry.clear despawns above).
        net.swofty.reload.ReloadRegistry.register("goal-types",
                net.swofty.mobs.ai.GoalTypeRegistry::clear);
        // packet handlers
        net.swofty.reload.ReloadRegistry.register("packet-handlers",
                net.swofty.packets.PacketListeners::clear);
        // inline first-class handlers
        net.swofty.reload.ReloadRegistry.register("inline-handlers",
                net.swofty.handlers.InlineHandlerRuntime::teardown);
        // script-spawned entities/projectiles (despawn)
        net.swofty.reload.ReloadRegistry.register("script-entities",
                net.swofty.entities.ScriptEntityRegistry::removeAll);
        // per-entity script state + native combat trackers (i-frames/fall)
        net.swofty.reload.ReloadRegistry.register("entity-state",
                net.swofty.entities.EntityStateStore::clearAll);
        net.swofty.reload.ReloadRegistry.register("combat-trackers",
                net.swofty.entities.EntityCombatTrackers::clearAll);
        // per-object task registry (<obj>.tasks.<id>)
        net.swofty.reload.ReloadRegistry.register("object-tasks",
                net.swofty.tasks.TaskRegistry::clearAll);
        // entity nametag holder lines
        net.swofty.reload.ReloadRegistry.register("entity-nametags",
                net.swofty.entities.EntityNametagRuntime::teardown);
        // dispenser block-entity inventories/state
        net.swofty.reload.ReloadRegistry.register("dispensers",
                net.swofty.blocks.DispenserRuntime::reset);
        // block_handler / placement_rule model maps
        net.swofty.reload.ReloadRegistry.register("block-handlers",
                net.swofty.blocks.BlockHandlerRuntime::teardown);
        net.swofty.reload.ReloadRegistry.register("placement-rules",
                net.swofty.blocks.PlacementRuleRuntime::teardown);
        // script-spawned displays (runtime display() builtin — orphaned on reload)
        net.swofty.reload.ReloadRegistry.register("displays",
                net.swofty.displays.DisplayRegistry::destroyAll);
        // nominal-type / struct registry
        net.swofty.reload.ReloadRegistry.register("struct-registry",
                net.swofty.structs.StructRegistry::clear);
        // music: stop playing songs + drop the song registry
        net.swofty.reload.ReloadRegistry.register("music", () -> {
            net.swofty.music.MusicRuntime.stopAll();
            net.swofty.music.SongRegistry.clear();
        });
        // http api server
        net.swofty.reload.ReloadRegistry.register("http-server",
                net.swofty.http.HttpRuntime::stop);
        // schedulers (named + anonymous every/schedule/repeat) — torn down first
        net.swofty.reload.ReloadRegistry.register("schedulers",
                net.swofty.sched.ScheduleRegistry::cancelAll);
        // async tasks + in-flight futures (§1.8.0): cancel every spawn/async
        // body and pending Future so a reload's tick-side continuations skip
        // and awaiting vthreads unwind against the torn-down program
        net.swofty.reload.ReloadRegistry.register("async-tasks",
                net.swofty.async.AsyncRuntime::cancelAll);
        // fishing engine + loot tables
        net.swofty.reload.ReloadRegistry.register("fishing", () -> {
            net.swofty.fishing.FishingRuntime.reset();
            net.swofty.fishing.FishingLootRegistry.clear();
        });
    }

    /** Phase-8 runtimes: seen-players listeners + the fishing engine. */
    private void registerPhase8() {
        net.swofty.players.PlayersRuntime.init();
        net.swofty.fishing.FishingLootRegistry.clear();
        for (net.swofty.model.FishingLootModel table : fishingLoot) {
            net.swofty.fishing.FishingLootRegistry.register(table);
        }
        if (!fishingLoot.isEmpty()) {
            System.out.println("Registered " + fishingLoot.size()
                    + " fishing loot table(s)");
        }
        net.swofty.fishing.FishingRuntime.init(serverConfig);
    }

    /** Phase-6 runtimes (design 6B/6D): tps, motd, permissions, http, every. */
    private void registerPhase6() {
        net.swofty.tps.TpsMonitor.init();
        net.swofty.motd.MotdRuntime.init(serverConfig);
        net.swofty.music.SongRegistry.clear();

        if (serverConfig != null && serverConfig.permissions() != null) {
            net.swofty.permissions.Permissions.setProvider(
                    new net.swofty.permissions.MapPermissionProvider(
                            serverConfig.permissions()));
            System.out.println("Permissions: server{} map provider with "
                    + serverConfig.permissions().size() + " entry(ies)");
        }

        if (serverConfig != null && serverConfig.hasHttp()) {
            try {
                net.swofty.http.HttpRuntime.start(
                        serverConfig.httpBind(), serverConfig.httpPort(), apis);
            } catch (Exception e) {
                System.err.println("Error: http server failed to start on "
                        + serverConfig.httpBind() + ":" + serverConfig.httpPort()
                        + " - " + e.getMessage());
            }
        } else if (!apis.isEmpty()) {
            System.err.println("Warning: " + apis.size() + " api declaration(s) but no "
                    + "server { http { port: ... } } block - the http server is off");
        }

        for (net.swofty.model.EveryDeclModel decl : everyDecls) {
            net.swofty.sched.ScheduleRuntime.startEvery(decl);
        }
        if (!everyDecls.isEmpty()) {
            System.out.println("Started " + everyDecls.size() + " every-schedule(s)");
        }
    }

    /**
     * Comprehensive hot-reload after a script changed on disk. Tears down
     * EVERY live registration whose behavior/line numbers come from the old
     * compiled JSON, re-scans + re-parses every script (so each Statement node
     * carries freshly-stamped file/line numbers), then re-registers every
     * declaration kind through the SAME path used at startup. This keeps the
     * VS Code tracer pulsing on the right lines for scoreboards, tablists,
     * bossbars, schedulers, mobs and every other decl kind — not just the
     * commands and events the old scoped reload refreshed.
     *
     * <p>Teardown is expressed generically as "drop the old registrations,
     * then re-run the loader": commands + event listeners are unregistered
     * here, and the shared {@link #collectDeclarations()} / {@link #register()}
     * pair does the rest — {@code collectDeclarations()} cancels every live
     * schedule (named AND anonymous) via {@code ScheduleRegistry.cancelAll()},
     * and {@code register()} has each content runtime clear/teardown its live
     * set (UI auto-refresh tasks, spawned mobs, holograms, npcs, packet/block/
     * item/fishing handlers, GUIs) before re-registering it, and restarts the
     * HTTP server (which stops the previous one first). Because reload simply
     * re-runs those two methods, any decl kind added to them in the future is
     * covered automatically.
     *
     * <p>PRESERVED across a reload: persistent variables, the PersistStore
     * backend, the seen-players store and loaded world data are all left
     * untouched — {@code initializePersistence()} and {@code WorldsRuntime}
     * are deliberately NOT re-run — so persistent/session state survives.
     *
     * <p>Idempotent and double-register-safe (runtime registries replace by
     * name / clear-then-add), and tick-safe: the caller applies it on the tick
     * thread via {@code scheduleNextTick}. MUST run on the tick thread.
     */
    public synchronized void reload() {
        // 1) run EVERY subsystem's teardown callback in reverse registration
        //    order via the central ReloadRegistry (#58): schedulers/tasks first,
        //    then spawned entities/mobs/holograms/npcs (despawn), displays,
        //    viewers/HUD tasks, packet/inline/block handlers, the reactive-
        //    instance index, the struct/nominal-type registries, http/music, and
        //    finally the event listeners + commands. This closes the gaps where
        //    teardown used to live ONLY in shutdown() (music, displays, script
        //    entities, fishing) and so was skipped on reload. The PersistStore is
        //    never torn down, so persistent values survive; register() below re-
        //    derives the reactive-instance liveness from those surviving roots.
        net.swofty.reload.ReloadRegistry.runTeardown();

        // 2) re-scan + re-parse every script: fresh execute blocks, functions,
        //    and freshly-stamped file/line numbers on every Statement node.
        //    processCommands/processEvents rebuild the command + event models;
        //    collectDeclarations re-parses all decl models and, up front,
        //    cancels every live schedule (named + anonymous) so no old-code
        //    loop survives.
        scriptLoader.scanScripts();
        commandProcessor.processCommands();
        eventProcessor.processEvents();
        collectDeclarations();

        // 3) re-register everything from the freshly-parsed JSON via the SAME
        //    startup registration path (commands + events + all decl kinds).
        //    Persistence + worlds are intentionally NOT re-initialized here.
        register();
    }

    /**
     * The server { ... } block, or null when no script declares one
     */
    public ServerConfigModel getServerConfig() {
        return serverConfig;
    }

    /**
     * Get the command processor
     */
    public CommandProcessor getCommandProcessor() {
        return commandProcessor;
    }

    public EventProcessor getEventProcessor() {
        return eventProcessor;
    }

    /**
     * Get the script loader
     */
    public ScriptLoader getScriptLoader() {
        return scriptLoader;
    }
}
