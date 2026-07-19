package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.command.builder.CommandResult;
import net.minestom.server.command.builder.condition.CommandCondition;
import net.minestom.server.entity.Player;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.swofty.async.AsyncRuntime;
import net.swofty.command.MinestomCommandRegistrar;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.nativebridge.representation.Command;
import net.swofty.permissions.MapPermissionProvider;
import net.swofty.permissions.Permissions;
import net.swofty.props.PropertyTables;

/**
 * --worlds-test: headless MinecraftServer.init() coverage of the phase-6
 * surfaces that need a live server process (design 6B/6D): the FULL
 * worlds round-trip (create polar world via the file loader AND via a
 * sqlite polar_storage_loader, set blocks, save, unload, reload, assert
 * block_at survives — driven end-to-end through a swoftc-compiled
 * script) and command permission ENFORCEMENT (a denied and an allowed
 * player through the real registrar condition + live dispatch).
 * Exits the JVM explicitly because init() starts non-daemon threads.
 */
public final class Phase6Smoke {
    private static final long ASYNC_TIMEOUT_MILLIS = 30_000;

    private Phase6Smoke() {
    }

    /**
     * The worlds round-trip runs through the real language surface: the
     * script is compiled by swoftc (so the typechecker accepts it) and
     * executed by ASTExecutor. Both worlds are named "world" (created
     * sequentially) because block_at()/set block resolve the
     * InstanceRegistry "world" fallback for non-player senders — the
     * frozen 6D surface has no explicit world argument.
     */
    private static final String SCRIPT = """
            command "polarfile" {
                execute async {
                    set loader to polar_loader("@PF_DIR@")
                    create world "world" with loader
                    set fresh to block_at(location(1, 40, 1))
                    send "fresh: ${fresh}" to sender
                    set block at location(1, 40, 1) to "DIAMOND_BLOCK"
                    set block at location(30, 64, -17) to "GOLD_BLOCK"
                    set pre_a to block_at(location(1, 40, 1))
                    set pre_b to block_at(location(30, 64, -17))
                    send "pre: ${pre_a} ${pre_b}" to sender
                    save world "world"
                    unload world "world" without saving
                    load world "world" with loader
                    set post_a to block_at(location(1, 40, 1))
                    set post_b to block_at(location(30, 64, -17))
                    send "post: ${post_a} ${post_b}" to sender
                    set still to world_exists("world", loader)
                    send "exists: ${still}" to sender
                    unload world "world" without saving
                }
            }

            command "polarstorage" {
                execute async {
                    set loader to polar_storage_loader(sqlite "@DB_PATH@")
                    create world "world" with loader
                    set fresh to block_at(location(-5, 10, 7))
                    send "sfresh: ${fresh}" to sender
                    set block at location(-5, 10, 7) to "EMERALD_BLOCK"
                    save world "world"
                    unload world "world" without saving
                    load world "world" with loader
                    set post to block_at(location(-5, 10, 7))
                    send "spost: ${post}" to sender
                    loop all_worlds(loader) as w {
                        send "stored: ${w}" to sender
                    }
                    unload world "world" without saving
                }
            }

            command "guarded" {
                permission: "arena.use"
                execute {
                    send "guarded ran" to sender
                }
            }
            """;

    public static int run() throws Exception {
        MinecraftServer ignored = MinecraftServer.init();
        PropertyTables.ensureRegistered();

        Path dir = Files.createTempDirectory("swoft-phase6-smoke");
        Path worldsDir = dir.resolve("worlds");
        Path db = dir.resolve("worlds.db");
        Path script = dir.resolve("phase6smoke.sw");
        Files.writeString(script, SCRIPT
                .replace("@PF_DIR@", worldsDir + "/")
                .replace("@DB_PATH@", db.toString()));

        ParsedScript parsed = SwoftJsonLoader.load(SwoftcCompiler.compile(script.toFile()));

        int failures = 0;
        failures += runCommand(parsed, "polarfile", List.of(
                "fresh: minecraft:air",
                "pre: minecraft:diamond_block minecraft:gold_block",
                "post: minecraft:diamond_block minecraft:gold_block",
                "exists: true"));
        failures += polarFileOnDisk(worldsDir);
        failures += runCommand(parsed, "polarstorage", List.of(
                "sfresh: minecraft:air",
                "spost: minecraft:emerald_block",
                "stored: world"));
        failures += sqliteBlobOnDisk(db);
        failures += permissionEnforcement(parsed);
        return failures == 0 ? 0 : 1;
    }

    /**
     * --http-serve &lt;script.sw&gt; &lt;seconds&gt;: compile a script with api
     * declarations, start HttpRuntime on an ephemeral port (printed as
     * HTTP_PORT=N), and serve for the given time so an external client
     * (curl) can do a live round-trip. Minestom is init'd (not started)
     * so handlers may use player() lookups and server properties.
     */
    public static int httpServe(String scriptPath, int seconds) throws Exception {
        MinecraftServer ignored = MinecraftServer.init();
        PropertyTables.ensureRegistered();
        ParsedScript parsed = SwoftJsonLoader.load(
                SwoftcCompiler.compile(new java.io.File(scriptPath)));
        if (parsed.apis().isEmpty()) {
            System.err.println("[HTTP-SERVE] script declares no api blocks");
            return 1;
        }
        net.swofty.http.HttpRuntime.start("127.0.0.1", 0, parsed.apis());
        System.out.println("HTTP_PORT=" + net.swofty.http.HttpRuntime.boundPort());
        Thread.sleep(seconds * 1000L);
        net.swofty.http.HttpRuntime.stop();
        return 0;
    }

    // ------------------------------------------------------------------
    // Worlds round-trip (design 6B): script-driven, asserted by output
    // ------------------------------------------------------------------

    private static int runCommand(ParsedScript parsed, String name, List<String> expected) {
        Command command = find(parsed, name);
        SyncSender sender = new SyncSender();
        try {
            net.swofty.ASTExecutor executor = new net.swofty.ASTExecutor(
                    sender, new java.util.HashMap<>());
            if (command.getExecuteBlock().isAsync()) {
                AsyncRuntime.start("phase6-smoke " + name,
                        () -> executor.execute(command.getExecuteBlock()));
                if (!AsyncRuntime.awaitAll(ASYNC_TIMEOUT_MILLIS)) {
                    System.err.println("[WORLDS] FAIL " + name + " timed out with "
                            + AsyncRuntime.taskCount() + " task(s) pending");
                    AsyncRuntime.cancelAll();
                    return 1;
                }
            } else {
                executor.execute(command.getExecuteBlock());
            }
        } catch (Exception e) {
            System.err.println("[WORLDS] FAIL " + name + " threw: " + e.getMessage());
            e.printStackTrace();
            return 1;
        }
        if (!sender.messages.equals(expected)) {
            System.err.println("[WORLDS] FAIL " + name);
            System.err.println("[WORLDS] expected: " + expected);
            System.err.println("[WORLDS] actual:   " + sender.messages);
            return 1;
        }
        System.out.println("[WORLDS] PASS " + name + ": " + expected);
        return 0;
    }

    private static int polarFileOnDisk(Path worldsDir) throws Exception {
        Path polar = worldsDir.resolve("world.polar");
        if (!Files.isRegularFile(polar) || Files.size(polar) == 0) {
            System.err.println("[WORLDS] FAIL expected a non-empty " + polar);
            return 1;
        }
        System.out.println("[WORLDS] PASS polar file on disk: " + polar.getFileName()
                + " (" + Files.size(polar) + " bytes)");
        return 0;
    }

    private static int sqliteBlobOnDisk(Path db) throws Exception {
        try (Connection connection = DriverManager.getConnection("jdbc:sqlite:" + db);
                Statement statement = connection.createStatement();
                ResultSet rows = statement.executeQuery(
                        "SELECT key, length(value) FROM swoft_persist"
                                + " WHERE var = 'swoft_worlds'")) {
            while (rows.next()) {
                if (rows.getString(1).equals("world") && rows.getLong(2) > 0) {
                    System.out.println("[WORLDS] PASS sqlite blob on disk: world ("
                            + rows.getLong(2) + " bytes of base64)");
                    return 0;
                }
            }
        }
        System.err.println("[WORLDS] FAIL no 'world' blob in sqlite " + db);
        return 1;
    }

    // ------------------------------------------------------------------
    // Permission enforcement (design 6D): denied + allowed, through the
    // registrar condition AND a live CommandManager dispatch
    // ------------------------------------------------------------------

    private static int permissionEnforcement(ParsedScript parsed) {
        int failures = 0;
        new MinestomCommandRegistrar().registerCommand(find(parsed, "guarded"));
        Permissions.setProvider(new MapPermissionProvider(Map.of(
                "Alice", List.of("arena.use", "admin.*"),
                "*", List.of("chat.use"))));
        try {
            FakeConnection aliceWire = new FakeConnection();
            FakeConnection bobWire = new FakeConnection();
            Player alice = new Player(aliceWire, new GameProfile(UUID.randomUUID(), "Alice"));
            Player bob = new Player(bobWire, new GameProfile(UUID.randomUUID(), "Bob"));

            CommandCondition condition = MinecraftServer.getCommandManager()
                    .getCommand("guarded").getCondition();
            failures += expect("condition allows Alice", true,
                    condition.canUse(alice, null));
            failures += expect("condition denies Bob", false,
                    condition.canUse(bob, null));
            failures += expect("condition allows console", true, condition.canUse(
                    MinecraftServer.getCommandManager().getConsoleSender(), null));

            CommandResult allowed = MinecraftServer.getCommandManager()
                    .execute(alice, "guarded");
            failures += expect("dispatch Alice result", CommandResult.Type.SUCCESS,
                    allowed.getType());
            failures += expect("Alice saw the command output", true,
                    aliceWire.sawMessage("guarded ran"));

            CommandResult denied = MinecraftServer.getCommandManager()
                    .execute(bob, "guarded");
            failures += expect("dispatch Bob result", CommandResult.Type.CANCELLED,
                    denied.getType());
            failures += expect("Bob saw no command output", false,
                    bobWire.sawMessage("guarded ran"));

            // node semantics on real players: wildcard prefix + "*" user
            failures += expect("Alice admin.* wildcard", true,
                    Permissions.check(alice, "admin.kick"));
            failures += expect("everyone rule chat.use", true,
                    Permissions.check(bob, "chat.use"));
            failures += expect("Bob denied arena.use", false,
                    Permissions.check(bob, "arena.use"));
        } finally {
            Permissions.setProvider(null);
        }
        System.out.println("[PERMS-E2E] " + (failures == 0
                ? "PASS: registrar condition + live dispatch (allowed & denied) + node matrix"
                : failures + " check(s) failed"));
        return failures;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[CHECK] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    private static Command find(ParsedScript parsed, String name) {
        for (Command command : parsed.commands()) {
            if (command != null && name.equals(command.getName())) {
                return command;
            }
        }
        throw new IllegalStateException("script lost command '" + name + "'");
    }

    /** Records outbound packets; message text is matched via toString. */
    static final class FakeConnection extends PlayerConnection {
        final List<SendablePacket> sent = new CopyOnWriteArrayList<>();

        @Override
        public void sendPacket(SendablePacket packet) {
            sent.add(packet);
        }

        @Override
        public SocketAddress getRemoteAddress() {
            return new InetSocketAddress(0);
        }

        boolean sawMessage(String text) {
            for (SendablePacket packet : sent) {
                if (String.valueOf(packet).contains(text)) {
                    return true;
                }
            }
            return false;
        }
    }

    /** Thread-safe capture: schedule bodies send from virtual threads. */
    static final class SyncSender implements CommandSender {
        final List<String> messages = new CopyOnWriteArrayList<>();

        @Override
        public void sendMessage(String message) {
            messages.add(message);
            System.out.println("[OUT] " + message);
        }

        // send now renders MiniMessage to a Component; capture its plain text
        @Override
        public void sendMessage(net.kyori.adventure.text.Component message) {
            sendMessage(net.swofty.TextFormat.plain(message));
        }

        @Override
        public net.kyori.adventure.identity.Identity identity() {
            return net.kyori.adventure.identity.Identity.nil();
        }

        @Override
        public net.minestom.server.tag.TagHandler tagHandler() {
            return net.minestom.server.tag.TagHandler.newHandler();
        }

        @Override
        public String toString() {
            return "Harness";
        }
    }
}
