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
        net.swofty.sched.ScheduleRegistry.cancelAll();
        net.swofty.http.HttpRuntime.stop();
        net.swofty.music.MusicRuntime.stopAll();
        net.swofty.displays.DisplayRegistry.destroyAll();
        net.swofty.holograms.HologramRuntime.teardown();
        net.swofty.npcs.NpcRuntime.teardown();
        net.swofty.handlers.InlineHandlerRuntime.teardown();
        net.swofty.blocks.BlockHandlerRuntime.teardown();
        net.swofty.blocks.PlacementRuleRuntime.teardown();
        net.swofty.fishing.FishingRuntime.reset();
        net.swofty.entities.ScriptEntityRegistry.removeAll();
        net.swofty.entities.EntityStateStore.clearAll();
        net.swofty.entities.EntityCombatTrackers.clearAll();
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
        System.out.println("Processed " + guis.size() + " guis, " + scoreboards.size()
                + " scoreboards, " + tablists.size() + " tablists, " + bossbars.size()
                + " bossbars, " + persistents.size() + " persistents, " + items.size()
                + " items, " + mobs.size() + " mobs, " + packetHandlers.size()
                + " packet handlers");
    }

    /**
     * Register all components with their respective systems
     */
    public void register() {
        // Register commands
        commandProcessor.register();

        // Register events
        eventProcessor.registerEvents();

        // Wire the gui/ui runtimes and hand them the declarations. On reload,
        // cancel the previous auto-refresh tasks first so scoreboards/tablists/
        // bossbars don't accumulate stale-model tasks tracing OLD line numbers
        // (no-op on first startup; live viewers are preserved either way).
        GuiRuntime.init();
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
        // 1) tear down the old command registrations and event listeners.
        //    (The remaining decl kinds are torn down inside the shared
        //    collectDeclarations()/register() pair invoked below, so their
        //    teardown stays identical to startup and can never drift.)
        var commandManager = net.minestom.server.MinecraftServer.getCommandManager();
        for (String name : new ArrayList<>(commandProcessor.getCommandMap().keySet())) {
            var existing = commandManager.getCommand(name);
            if (existing != null) {
                commandManager.unregister(existing);
            }
        }
        eventProcessor.getEventRegistrar().reset();

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
