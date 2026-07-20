package net.swofty.harness;

import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.Collections;
import java.util.UUID;

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import net.minestom.server.Auth;
import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.player.PlayerSpawnEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;

import net.swofty.ASTExecutor;
import net.swofty.InstanceRegistry;
import net.swofty.SwoftLangEngine;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.debug.DebugServer;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.nativebridge.representation.Command;
import net.swofty.persist.PersistStore;
import net.swofty.props.PropertyTables;
import net.swofty.runtime.SystemSender;
import net.swofty.sched.ScheduleHandle;
import net.swofty.sched.ScheduleRegistry;
import net.swofty.ui.SwoftSidebarRuntime;

/**
 * Headless smoke for the debug tracer (VS Code extension Part 3):
 *  1. flips {@link DebugServer#enabled}, executes a command handler, and
 *     asserts a trace event fired for every statement with the right file +
 *     line, bracketed by handler enter/exit;
 *  2. connects a raw WebSocket client to a live {@link DebugServer} and asserts
 *     the hello frame arrives.
 */
public final class DebugSmoke {
    private static final String REL_FILE = "scripts/debugdemo.sw";

    private static final String SCRIPT = """
            command "demo" {
                execute {
                    set x to 1
                    set x to x + 1
                    if x > 1 {
                        send "big" to sender
                    }
                }
            }
            """;

    /**
     * Invoked directly (java net.swofty.harness.DebugSmoke) or through the
     * gradle {@code debugSmoke} task. {@link #reloadEngineSmoke()} starts a
     * MinecraftServer (non-daemon threads), so main() must always exit
     * explicitly once the checks are done.
     */
    public static void main(String[] args) {
        int code;
        try {
            code = run();
        } catch (Exception e) {
            e.printStackTrace();
            code = 1;
        }
        System.exit(code);
    }

    public static int run() throws Exception {
        int failures = 0;
        failures += traceSmoke();
        failures += wsConnectSmoke();
        failures += reloadSmoke();
        // the comprehensive-reload end-to-end check inits a MinecraftServer, so
        // run it last (its threads keep the JVM up until main() System.exit)
        failures += reloadEngineSmoke();
        if (failures == 0) {
            System.out.println("[debug-smoke] OK");
        } else {
            System.err.println("[debug-smoke] " + failures + " check(s) failed");
        }
        return failures == 0 ? 0 : 1;
    }

    /** Execute a handler with tracing on and assert the emitted events. */
    private static int traceSmoke() throws Exception {
        Path dir = Files.createTempDirectory("swoft-debug-smoke");
        File script = dir.resolve("debugdemo.sw").toFile();
        Files.writeString(script.toPath(), SCRIPT);
        String json = SwoftcCompiler.compile(script);
        ParsedScript parsed = SwoftJsonLoader.load(json, REL_FILE);

        List<String> messages = new CopyOnWriteArrayList<>();
        DebugServer.setTestListener(messages::add);
        DebugServer.enabled = true;
        try {
            for (Command command : parsed.commands()) {
                if (command != null && command.getExecuteBlock() != null) {
                    new ASTExecutor(new SystemSender(true), new HashMap<>())
                            .execute(command.getExecuteBlock());
                }
            }
        } finally {
            DebugServer.enabled = false;
            DebugServer.setTestListener(null);
        }

        int failures = 0;
        List<JsonObject> traces = new ArrayList<>();
        List<JsonObject> handlers = new ArrayList<>();
        for (String message : messages) {
            JsonObject obj = JsonParser.parseString(message).getAsJsonObject();
            switch (obj.get("type").getAsString()) {
                case "trace" -> traces.add(obj);
                case "handler" -> handlers.add(obj);
                default -> { }
            }
        }

        if (traces.isEmpty()) {
            System.err.println("[debug-smoke] no trace events emitted");
            failures++;
        }
        for (JsonObject trace : traces) {
            if (!REL_FILE.equals(optString(trace, "file"))) {
                System.err.println("[debug-smoke] trace has wrong file: " + trace);
                failures++;
                break;
            }
            if (trace.get("line").getAsInt() <= 0) {
                System.err.println("[debug-smoke] trace missing line: " + trace);
                failures++;
                break;
            }
        }
        failures += expectKind(traces, "assign");
        failures += expectKind(traces, "send");
        // every statement trace carries the handler tag
        boolean tagged = traces.stream()
                .anyMatch(t -> "command demo".equals(optString(t, "handler")));
        if (!tagged) {
            System.err.println("[debug-smoke] no trace tagged with 'command demo'");
            failures++;
        }
        // handler enter + exit for the command body
        boolean enter = handlers.stream().anyMatch(h -> "enter".equals(optString(h, "phase"))
                && "command demo".equals(optString(h, "name")));
        boolean exit = handlers.stream().anyMatch(h -> "exit".equals(optString(h, "phase"))
                && "command demo".equals(optString(h, "name")));
        if (!enter || !exit) {
            System.err.println("[debug-smoke] missing handler enter/exit (enter=" + enter
                    + ", exit=" + exit + ")");
            failures++;
        }
        System.out.println("[debug-smoke] trace: " + traces.size() + " statements, "
                + handlers.size() + " handler events");
        return failures;
    }

    private static int expectKind(List<JsonObject> traces, String kind) {
        boolean found = traces.stream().anyMatch(t -> kind.equals(optString(t, "kind")));
        if (!found) {
            System.err.println("[debug-smoke] no trace of kind '" + kind + "'");
            return 1;
        }
        return 0;
    }

    /** Start a real DebugServer and assert a raw WS client gets the hello. */
    private static int wsConnectSmoke() {
        int port = freePort();
        if (port <= 0) {
            System.err.println("[debug-smoke] could not find a free port");
            return 1;
        }
        DebugServer.start(port, "/abs/scripts");
        try (Socket socket = new Socket("127.0.0.1", port)) {
            socket.setSoTimeout(3000);
            OutputStream out = socket.getOutputStream();
            String request = "GET / HTTP/1.1\r\n"
                    + "Host: localhost\r\n"
                    + "Upgrade: websocket\r\n"
                    + "Connection: Upgrade\r\n"
                    + "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
                    + "Sec-WebSocket-Version: 13\r\n\r\n";
            out.write(request.getBytes(StandardCharsets.US_ASCII));
            out.flush();

            InputStream in = socket.getInputStream();
            String status = readHttpResponse(in);
            if (!status.contains("101")) {
                System.err.println("[debug-smoke] handshake did not return 101: " + status);
                return 1;
            }
            String hello = readTextFrame(in);
            if (hello == null || !hello.contains("\"type\":\"hello\"")
                    || !hello.contains("/abs/scripts")) {
                System.err.println("[debug-smoke] bad hello frame: " + hello);
                return 1;
            }
            System.out.println("[debug-smoke] ws hello: " + hello);
            return 0;
        } catch (Exception e) {
            System.err.println("[debug-smoke] ws connect failed: " + e.getMessage());
            return 1;
        } finally {
            DebugServer.stop();
        }
    }

    /** Assert reload broadcasts encode ok and error results correctly. */
    private static int reloadSmoke() {
        List<String> messages = new CopyOnWriteArrayList<>();
        DebugServer.setTestListener(messages::add);
        try {
            DebugServer.reload(REL_FILE, true, null);
            DebugServer.reload(REL_FILE, false, "debugdemo.sw:4:9: error: boom");
        } finally {
            DebugServer.setTestListener(null);
        }
        int failures = 0;
        JsonObject ok = JsonParser.parseString(messages.get(0)).getAsJsonObject();
        JsonObject bad = JsonParser.parseString(messages.get(1)).getAsJsonObject();
        if (!"reload".equals(optString(ok, "type")) || !ok.get("ok").getAsBoolean()
                || !REL_FILE.equals(optString(ok, "file"))) {
            System.err.println("[debug-smoke] bad ok-reload: " + ok);
            failures++;
        }
        if (bad.get("ok").getAsBoolean() || !optString(bad, "error").contains("boom")) {
            System.err.println("[debug-smoke] bad error-reload: " + bad);
            failures++;
        }
        return failures;
    }

    private static String optString(JsonObject obj, String key) {
        return obj.has(key) && !obj.get(key).isJsonNull() ? obj.get(key).getAsString() : null;
    }

    private static int freePort() {
        try (ServerSocket socket = new ServerSocket(0)) {
            return socket.getLocalPort();
        } catch (Exception e) {
            return -1;
        }
    }

    private static String readHttpResponse(InputStream in) throws Exception {
        StringBuilder sb = new StringBuilder();
        int prev = -1;
        int cur;
        int matched = 0;
        while ((cur = in.read()) != -1) {
            sb.append((char) cur);
            if (prev == '\r' && cur == '\n') {
                if (++matched == 2) {
                    break;
                }
            } else if (cur != '\r') {
                matched = 0;
            }
            prev = cur;
        }
        return sb.toString();
    }

    private static String readTextFrame(InputStream in) throws Exception {
        int b0 = in.read();
        if (b0 < 0) {
            return null;
        }
        int b1 = in.read();
        int len = b1 & 0x7F;
        if (len == 126) {
            len = (in.read() << 8) | in.read();
        }
        byte[] payload = in.readNBytes(len);
        return new String(payload, StandardCharsets.UTF_8);
    }

    // ------------------------------------------------------------------
    // comprehensive hot-reload end-to-end smoke
    // ------------------------------------------------------------------

    private static final int SHIFT = 5;

    /** main.sw v1: owns a persistent var, scoreboard, mob, anon every, event. */
    private static final String MAIN_V1 = """
            storage {
                backend: files "%DATA%"
            }

            persistent counter: Integer = 0

            scoreboard "hud" {
                title: "HUD"
                update: every 5 ticks
                lines {
                    line "alpha"
                    line "beta"
                }
            }

            mob "zombie" {
                type: "ZOMBIE"
                health: 20
                ai: none
            }

            every 3600 seconds {
                broadcast "heartbeat"
            }

            event PlayerJoin {
                execute {
                    send "joined" to event.player
                }
            }
            """;

    /** A sibling script whose named schedule must survive main.sw's reload. */
    private static final String SIBLING = """
            every 3600 seconds as "sibling-loop" {
                broadcast "sibling"
            }
            """;

    /** Broken main.sw: recompile must fail so the watcher keeps the old code. */
    private static final String MAIN_BROKEN = """
            scoreboard "hud" {
                title:
            }
            """;

    /**
     * End-to-end proof that the COMPREHENSIVE reload tears down and re-arms
     * every decl kind — not just commands/events. Loads a script owning a
     * scheduler + event + spawned mob + scoreboard (plus a sibling scheduler
     * and a persistent var), shifts its line numbers, reloads through the real
     * {@link SwoftLangEngine#reload()}, and asserts:
     *
     * <ul>
     *   <li>the scoreboard now traces the NEW line numbers (the tracer bug):
     *       a refresh reads the freshly-parsed model, and there is exactly ONE
     *       refresh task — no stale duplicate still tracing the old lines. The
     *       refresh model is the same object the auto-refresh task captured
     *       (both come from the runtime's DECLS map), so this is faithful;</li>
     *   <li>the OLD event listener detached (handler fires at the new line
     *       ONLY, never doubled at old+new);</li>
     *   <li>the OLD spawned mob despawned;</li>
     *   <li>no double-scheduler: the live schedule count is unchanged and the
     *       old anonymous every-handle is cancelled;</li>
     *   <li>the sibling script's named scheduler is still live (not leaked,
     *       dropped, or doubled) after main.sw reloads, and repeated reloads
     *       never accumulate schedules;</li>
     *   <li>the persistent variable and the PersistStore backend survive;</li>
     *   <li>a compile error during watch keeps the previous version running.</li>
     * </ul>
     */
    private static int reloadEngineSmoke() throws Exception {
        Path root = Files.createTempDirectory("swoft-reload-smoke");
        Path scriptsDir = root.resolve("scripts");
        Files.createDirectories(scriptsDir);
        Path dataDir = root.resolve("data");
        Path mainFile = scriptsDir.resolve("main.sw");
        Path siblingFile = scriptsDir.resolve("sibling.sw");
        String mainV1 = MAIN_V1.replace("%DATA%", dataDir.toString().replace("\\", "/"));
        Files.writeString(mainFile, mainV1);
        Files.writeString(siblingFile, SIBLING);

        MinecraftServer.init(new Auth.Offline());
        MinecraftServer.getExceptionManager().setExceptionHandler(Throwable::printStackTrace);
        PropertyTables.ensureRegistered();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        Player p1 = new Player(new FakeConn(), new GameProfile(UUID.randomUUID(), "P1"));
        p1.setInstance(instance, new Pos(0.5, 41, 0.5)).join();

        List<String> msgs = new CopyOnWriteArrayList<>();
        DebugServer.setTestListener(msgs::add);
        DebugServer.enabled = true;

        SwoftLangEngine engine = new SwoftLangEngine(scriptsDir.toString(), "sw");
        int failures = 0;
        try {
            engine.initialize();
            engine.register();

            // ---- persistence: seed a value + capture the live backend ----
            PersistStore store = PersistStore.active();
            failures += expect("PersistStore initialized for the persistent var",
                    true, store != null);
            if (store != null) {
                store.set("counter", "", 7);
                failures += expect("persistent 'counter' reads back 7 before reload",
                        7, asInt(store.get("counter", "")));
            }

            // ---- mob: spawn one, prove it is live ----
            SwoftMob mob = MobRegistry.spawn("zombie", new Pos(0.5, 41, 3.5), instance);
            failures += expect("spawned mob is live before reload", true,
                    MobRegistry.all(null).contains(mob) && !mob.isRemoved());

            // ---- scoreboard: show it, prove exactly one refresh task ----
            SwoftSidebarRuntime.show("hud", p1);
            failures += expect("exactly one scoreboard refresh task before reload",
                    1, SwoftSidebarRuntime.taskCount());
            List<Integer> boardBefore = captureMainLines(msgs,
                    () -> SwoftSidebarRuntime.update(p1));
            failures += expect("scoreboard refresh traced its 2 lines before reload",
                    2, boardBefore.size());

            // ---- event: fire PlayerJoin, capture the handler's line ----
            List<Integer> evBefore = captureMainLines(msgs, () -> EventDispatcher.call(
                    new PlayerSpawnEvent(p1, instance, true)));
            failures += expect("event handler traced once before reload", 1,
                    evBefore.size());

            // ---- schedulers: main anon + sibling named are both live ----
            failures += expect("two live schedules before reload (anon + sibling)",
                    2, ScheduleRegistry.liveCount());
            ScheduleHandle oldAnon = null;
            for (ScheduleHandle h : ScheduleRegistry.liveHandles()) {
                if (h.name() == null) {
                    oldAnon = h;
                }
            }
            failures += expect("captured the anonymous every-handle", true, oldAnon != null);
            ScheduleHandle sibling = ScheduleRegistry.lookup("sibling-loop");
            failures += expect("sibling named schedule is running before reload",
                    true, sibling != null && sibling.isRunning());

            // ================= EDIT + RELOAD =================
            // prepend SHIFT blank lines so every line number moves down by SHIFT
            Files.writeString(mainFile, "\n".repeat(SHIFT) + mainV1);
            engine.reload();

            // ---- persistence survived (same backend instance + value kept) ----
            failures += expect("PersistStore backend survived reload (same instance)",
                    true, PersistStore.active() == store);
            failures += expect("persistent 'counter' still 7 after reload", 7,
                    store == null ? -1 : asInt(store.get("counter", "")));

            // ---- old mob despawned by the reload teardown ----
            failures += expect("old spawned mob despawned after reload", true,
                    mob.isRemoved() && !MobRegistry.all(null).contains(mob));

            // ---- scoreboard: still one task, now tracing the NEW lines ----
            failures += expect("still exactly one scoreboard refresh task after reload",
                    1, SwoftSidebarRuntime.taskCount());
            List<Integer> boardAfter = captureMainLines(msgs,
                    () -> SwoftSidebarRuntime.update(p1));
            failures += expect("scoreboard traces shifted to the NEW line numbers "
                    + "(the tracer bug): " + boardBefore + " -> " + boardAfter,
                    shift(boardBefore), boardAfter);

            // ---- event: old listener detached — fires at the new line ONLY ----
            List<Integer> evAfter = captureMainLines(msgs, () -> EventDispatcher.call(
                    new PlayerSpawnEvent(p1, instance, true)));
            failures += expect("event handler fires ONCE at the new line after reload "
                    + "(old listener detached): " + evBefore + " -> " + evAfter,
                    shift(evBefore), evAfter);

            // ---- schedulers: no double, old anon cancelled, sibling still live ----
            failures += expect("still two live schedules after reload (no doubling)",
                    2, ScheduleRegistry.liveCount());
            failures += expect("old anonymous every-handle was cancelled by reload",
                    true, oldAnon == null || oldAnon.isCancelled());
            ScheduleHandle siblingAfter = ScheduleRegistry.lookup("sibling-loop");
            failures += expect("sibling named schedule still live after main.sw reload",
                    true, siblingAfter != null && siblingAfter.isRunning());

            // ---- repeated reloads must not accumulate schedules ----
            engine.reload();
            failures += expect("live schedule count stays 2 across repeated reloads",
                    2, ScheduleRegistry.liveCount());

            // ---- compile error during watch keeps the previous version live ----
            List<Integer> good = captureMainLines(msgs, () -> EventDispatcher.call(
                    new PlayerSpawnEvent(p1, instance, true)));
            Files.writeString(mainFile, MAIN_BROKEN);
            boolean threw = false;
            try {
                SwoftcCompiler.compile(mainFile.toFile(),
                        engine.getScriptLoader().addonPath());
            } catch (Exception e) {
                threw = true; // the watcher aborts here, never calling reload()
            }
            failures += expect("a broken script fails to recompile (watcher aborts)",
                    true, threw);
            List<Integer> stillGood = captureMainLines(msgs, () -> EventDispatcher.call(
                    new PlayerSpawnEvent(p1, instance, true)));
            failures += expect("after a failed recompile the old handler still runs "
                    + "unchanged: " + good + " vs " + stillGood, good, stillGood);

            System.out.println("[debug-smoke] reload-engine: "
                    + (failures == 0 ? "PASS" : failures + " failure(s)"));
        } finally {
            DebugServer.enabled = false;
            DebugServer.setTestListener(null);
            try {
                engine.shutdown();
            } catch (RuntimeException ignored) {
            }
        }
        return failures;
    }

    /** Every line number in {@code lines} moved down by {@link #SHIFT}. */
    private static List<Integer> shift(List<Integer> lines) {
        List<Integer> out = new ArrayList<>();
        for (int l : lines) {
            out.add(l + SHIFT);
        }
        Collections.sort(out);
        return out;
    }

    /**
     * Run {@code action} and collect the sorted line numbers of every trace
     * event it emitted for main.sw. The listener fills synchronously (traces
     * fire on the caller's thread during a scoreboard refresh / event dispatch),
     * so the list is complete once {@code action} returns.
     */
    private static List<Integer> captureMainLines(List<String> msgs, Runnable action) {
        msgs.clear();
        action.run();
        List<Integer> lines = new ArrayList<>();
        for (String message : msgs) {
            JsonObject obj = JsonParser.parseString(message).getAsJsonObject();
            if (!"trace".equals(optString(obj, "type"))) {
                continue;
            }
            String file = optString(obj, "file");
            if (file != null && file.endsWith("main.sw")) {
                lines.add(obj.get("line").getAsInt());
            }
        }
        Collections.sort(lines);
        return lines;
    }

    private static int asInt(Object value) {
        return value instanceof Number n ? n.intValue() : Integer.MIN_VALUE;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[debug-smoke] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    /** A connection that records outbound packets and always reads online. */
    private static final class FakeConn extends PlayerConnection {
        private final List<SendablePacket> sent = new CopyOnWriteArrayList<>();

        @Override
        public void sendPacket(SendablePacket packet) {
            sent.add(packet);
        }

        @Override
        public SocketAddress getRemoteAddress() {
            return new InetSocketAddress(0);
        }

        // scoreboard refreshAll() skips offline viewers; a hand-built player is
        // never registered with the connection manager, so force it online.
        @Override
        public boolean isOnline() {
            return true;
        }
    }

    private DebugSmoke() {
    }
}
