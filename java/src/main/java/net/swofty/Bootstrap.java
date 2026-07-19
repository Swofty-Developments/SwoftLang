package net.swofty;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.player.AsyncPlayerConfigurationEvent;
import net.minestom.server.event.server.ServerListPingEvent;
import net.minestom.server.Auth;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.InstanceManager;
import net.minestom.server.instance.LightingChunk;
import net.minestom.server.instance.block.Block;
import net.swofty.async.AsyncRuntime;
import net.swofty.async.TickClock;
import net.swofty.model.ServerConfigModel;
import net.swofty.persist.PersistStore;

public class Bootstrap {
    /** How long shutdown waits for interrupted script tasks to finish. */
    private static final long SHUTDOWN_TASK_GRACE_MILLIS = 3_000;

    private static SwoftLangEngine swoftLangEngine;

    public static void main(String[] args) {
        // --debug [port]: host the live debug tracer (VS Code extension Part 3)
        // on the given ws port (default 25580) and hot-reload on script save.
        int debugPort = parseDebugPort(args);

        // Load SwoftLang scripts BEFORE MinecraftServer.init: auth is now a
        // construction-time choice (MinecraftServer.init(Auth)) rather than a
        // post-init toggle, and the auth kind comes from the server { } block,
        // so the script config must be resolved first. initialize() only parses
        // scripts and collects declarations — it never touches MinecraftServer.
        swoftLangEngine = new SwoftLangEngine();
        swoftLangEngine.initialize();
        ServerConfigModel config = swoftLangEngine.getServerConfig();

        // Initialize Minestom server with the resolved auth mode (always first)
        MinecraftServer server = MinecraftServer.init(resolveAuth(config));
        InstanceManager instanceManager = MinecraftServer.getInstanceManager();
        GlobalEventHandler globalEventHandler = MinecraftServer.getGlobalEventHandler();
        InstanceContainer instanceContainer = instanceManager.createInstanceContainer();
        // LightingChunk computes sky/block light; plain chunks render pitch
        // black. server { lighting: false } opts out (default on) — some
        // servers precompute/ship lighting or want the cheaper plain chunks.
        if (config == null || config.lighting()) {
            instanceContainer.setChunkSupplier(LightingChunk::new);
        }

        // Tick-aligned waits + task teardown for the async runtime, and a
        // final persistence flush on server stop. cancelAll() only
        // interrupts — it does not join — so wait (bounded) for script
        // tasks to unwind BEFORE the final flush; otherwise a straggler's
        // persist_set lands after the flush snapshot and is silently lost
        TickClock.init();
        MinecraftServer.getSchedulerManager().buildShutdownTask(() -> {
            net.swofty.sched.ScheduleRegistry.cancelAll();
            AsyncRuntime.cancelAll();
            if (!AsyncRuntime.awaitAll(SHUTDOWN_TASK_GRACE_MILLIS)) {
                System.err.println("Warning: " + AsyncRuntime.taskCount()
                        + " script task(s) still running at shutdown;"
                        + " their late persistent writes may be lost");
            }
            PersistStore.shutdownActive();
        });

        // Set the ChunkGenerator
        instanceContainer.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.GRASS_BLOCK));
        InstanceRegistry.register("world", instanceContainer);

        // Add an event callback to specify the spawning instance (and the spawn position)
        globalEventHandler.addListener(AsyncPlayerConfigurationEvent.class, event -> {
            final Player player = event.getPlayer();
            event.setSpawningInstance(instanceContainer);
            player.setRespawnPoint(new Pos(0, 42, 0));
        });

        String host = config != null ? config.host() : "0.0.0.0";
        int port = config != null ? config.port() : 25565;
        if (config != null && config.brand() != null) {
            MinecraftServer.setBrandName(config.brand());
        }
        // motd + favicon pings are handled by MotdRuntime (engine register)

        // Register all components with your server
        swoftLangEngine.register();

        // Start the debug tracer + hot-reload watcher once registration is done
        // and the scheduler exists (reloads apply on the tick thread).
        if (debugPort > 0) {
            net.swofty.debug.DebugServer.start(debugPort,
                    swoftLangEngine.getScriptLoader().scriptsDirAbsolute());
            new net.swofty.debug.ReloadWatcher(swoftLangEngine).start();
            MinecraftServer.getSchedulerManager().buildShutdownTask(
                    net.swofty.debug.DebugServer::stop);
        }

        // Start the server
        server.start(host, port);

        // server { open_to_lan: true } (design 6D extras OpenToLAN)
        if (config != null && config.openToLan()) {
            if (net.minestom.server.extras.lan.OpenToLAN.open()) {
                System.out.println("Server opened to LAN");
            } else {
                System.err.println("Warning: OpenToLAN failed to start");
            }
        }
    }

    /**
     * auth: mojang | velocity "secret" | bungeecord | offline — now expressed
     * as the {@link Auth} record passed into {@link MinecraftServer#init(Auth)}.
     * mojang means online mode ({@link Auth.Online}); the others map 1:1.
     */
    private static Auth resolveAuth(ServerConfigModel config) {
        String kind = config != null ? config.authKind() : "offline";
        switch (kind) {
            case "mojang" -> {
                return new Auth.Online();
            }
            case "velocity" -> {
                return new Auth.Velocity(config.authSecret());
            }
            case "bungeecord" -> {
                return new Auth.Bungee();
            }
            case "offline" -> {
                return new Auth.Offline();
            }
            default -> {
                System.err.println("Unknown auth kind '" + kind + "', staying offline");
                return new Auth.Offline();
            }
        }
    }

    /**
     * Parse {@code --debug [port]} from the CLI. Returns the ws port (the
     * optional numeric argument right after the flag, else the default 25580)
     * when {@code --debug} is present, or -1 when the tracer is off.
     */
    private static int parseDebugPort(String[] args) {
        for (int i = 0; i < args.length; i++) {
            if (!"--debug".equals(args[i])) {
                continue;
            }
            if (i + 1 < args.length) {
                try {
                    return Integer.parseInt(args[i + 1]);
                } catch (NumberFormatException ignored) {
                    // next arg is not a port — fall through to the default
                }
            }
            return 25580;
        }
        return -1;
    }

    /**
     * Access the SwoftLang engine from other parts of your application
     */
    public static SwoftLangEngine getSwoftLangEngine() {
        return swoftLangEngine;
    }
}
