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
        net.swofty.fishing.FishingRuntime.reset();
        net.swofty.entities.ScriptEntityRegistry.removeAll();
        net.swofty.worlds.WorldsRuntime.unloadAll();
        net.swofty.players.SeenPlayersStore.shutdownActive();
        PersistStore.shutdownActive();
    }

    /**
     * Gui/scoreboard/tablist/bossbar declarations and the server block;
     * at most one server block across all scripts (extras error + ignore)
     */
    private void collectDeclarations() {
        // reload wipes named schedules (cancelling any live ones) so the
        // fresh script's every/schedule-as declarations start clean
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

        // Wire the gui/ui runtimes and hand them the declarations
        GuiRuntime.init();
        UiRuntime.init();
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
        NametagRuntime.init();
        // dispenser block-entities: wipe stale inventories/state each reload
        net.swofty.blocks.DispenserRuntime.reset();
        net.swofty.blocks.DispenserRuntime.init();

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
     * Hot-reload the command and event handlers after a script changed on
     * disk. Tears down the currently registered commands and event listeners,
     * re-scans + re-parses every script (rebuilding fresh execute blocks and
     * function definitions), then re-registers the commands and events so the
     * new code runs. Scoped to commands/events (the tracer's live handlers) to
     * stay tick-safe and avoid disrupting persistence, HTTP, schedules, and
     * live GUIs mid-session. MUST run on the tick thread.
     */
    public synchronized void reload() {
        // 1) tear down the old command registrations and event listeners
        var commandManager = net.minestom.server.MinecraftServer.getCommandManager();
        for (String name : new ArrayList<>(commandProcessor.getCommandMap().keySet())) {
            var existing = commandManager.getCommand(name);
            if (existing != null) {
                commandManager.unregister(existing);
            }
        }
        eventProcessor.getEventRegistrar().reset();

        // 2) re-scan + re-parse: fresh execute blocks, functions re-registered
        scriptLoader.scanScripts();
        commandProcessor.processCommands();
        eventProcessor.processEvents();

        // 3) re-register with the new code
        commandProcessor.register();
        eventProcessor.registerEvents();
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
