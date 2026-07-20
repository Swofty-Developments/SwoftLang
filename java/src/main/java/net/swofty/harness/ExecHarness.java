package net.swofty.harness;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import net.kyori.adventure.identity.Identity;
import net.minestom.server.command.CommandSender;
import net.minestom.server.tag.TagHandler;
import net.swofty.ASTExecutor;
import net.swofty.async.AsyncRuntime;
import net.swofty.compiler.FunctionRegistry;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftFunction;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.model.PersistentDeclModel;
import net.swofty.model.StorageBackendModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.persist.PersistStore;
import net.swofty.nativebridge.representation.Command;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.event.events.SwoftPlayerChatEvent;
import net.swofty.event.events.SwoftPlayerJoinEvent;
import net.swofty.props.Coercions;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;
import net.swofty.props.PropertyTables;
import net.swofty.props.ThreadPolicy;
import org.jetbrains.annotations.NotNull;

/**
 * Headless harness: compiles/loads a script and executes every command and
 * event block against a capturing sender. Registers a TestThing property
 * table so property get/set chains (including wither hops) run serverless;
 * async scripts are joined with a timeout before exit.
 */
public class ExecHarness {
    private static final long ASYNC_TIMEOUT_MILLIS = 10_000;

    public static void main(String[] args) throws Exception {
        if ((args.length == 2 || args.length == 3) && args[0].equals("--persist-test")) {
            System.exit(persistTest(args[1], args.length == 3 ? args[2] : null));
        }
        if (args.length == 2 && args[0].equals("--items-demo")) {
            System.exit(Phase5Harness.itemsDemo(args[1]));
        }
        if (args.length == 1 && args[0].equals("--packets-check")) {
            System.exit(Phase5Harness.packetsCheck());
        }
        if (args.length == 2 && args[0].equals("--phase5-smoke")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = Phase5Smoke.run(args[1]);
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--module-test")) {
            System.exit(moduleTest());
        }
        if (args.length == 1 && args[0].equals("--phase6-checks")) {
            System.exit(Phase6Harness.phase6Checks());
        }
        if (args.length == 1 && args[0].equals("--http-test")) {
            System.exit(Phase6Harness.httpTest());
        }
        if (args.length == 1 && args[0].equals("--sched-test")) {
            System.exit(Phase6Harness.schedTest());
        }
        if (args.length == 1 && args[0].equals("--worlds-test")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = Phase6Smoke.run();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 3 && args[0].equals("--http-serve")) {
            int code;
            try {
                code = Phase6Smoke.httpServe(args[1], Integer.parseInt(args[2]));
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--phase7-smoke")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = Phase7Smoke.run();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--pvp-smoke")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = PvpSmoke.run();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 2 && args[0].equals("--npc-holo-smoke")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = NpcHoloSmoke.run(args[1]);
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 2 && args[0].equals("--inline-handlers-smoke")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = InlineHandlerSmoke.run(args[1]);
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 2 && args[0].equals("--perviewer-smoke")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = PerViewerSmoke.run(args[1]);
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--wevents-probe")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = WEventsProbe.run();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--phase8-checks")) {
            int code;
            try {
                code = Phase8Harness.run();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--phase9-checks")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = Phase9Harness.run();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--map-test")) {
            int code;
            try {
                code = Phase10Harness.mapTest();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--collections-test")) {
            int code;
            try {
                code = Phase10Harness.collectionsTest();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--debug-smoke")) {
            int code;
            try {
                code = DebugSmoke.run();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length == 1 && args[0].equals("--phase10-smoke")) {
            // MinecraftServer.init() starts non-daemon threads: always exit
            int code;
            try {
                code = Phase10Harness.smoke();
            } catch (Throwable t) {
                t.printStackTrace();
                code = 1;
            }
            System.exit(code);
        }
        if (args.length != 1) {
            System.err.println("Usage: ExecHarness <script.sw | script.sw.json"
                    + " | --check-props | --persist-test <script> [storage-path]"
                    + " | --items-demo <script> | --packets-check | --phase5-smoke <script>"
                    + " | --module-test | --phase6-checks | --http-test | --sched-test"
                    + " | --worlds-test | --phase7-smoke | --phase8-checks"
                    + " | --phase9-checks | --map-test | --collections-test"
                    + " | --phase10-smoke | --debug-smoke"
                    + " | --http-serve <script> <seconds>>");
            System.exit(1);
        }
        if (args[0].equals("--check-props")) {
            System.exit(checkProps());
        }

        ParsedScript parsed = loadScript(args[0]);

        registerTestProperties();

        FunctionRegistry.clear();
        for (SwoftFunction function : parsed.functions()) {
            FunctionRegistry.register(function);
        }

        // Scripts with persistents need an active store; plain runs get a
        // throwaway files backend so they never write into the repo
        boolean persistent = !parsed.persistents().isEmpty();
        if (persistent) {
            Path dir = Files.createTempDirectory("swoft-persist-run");
            PersistStore.initialize(parsed.persistents(), new StorageConfigModel(
                    StorageBackendModel.files(dir.toString()),
                    StorageConfigModel.DEFAULT_FLUSH_TICKS));
        }

        runAllBlocks(parsed);

        if (persistent) {
            PersistStore.shutdownActive();
        }
    }

    /**
     * Module-system end-to-end (design 6A): writes a two-module script pair
     * into a temp dir, compiles the entry (the import resolves against the
     * script's own directory), and proves BY OUTPUT that (1) exported
     * functions are callable across the module boundary, (2) module-level
     * vars are private module state — the entry's own 'count' variable and
     * the module's 'count' var live in different scopes, (3) private module
     * functions serve exported ones, and (4) a module imported by a second
     * entry script registers once, keeping one shared state.
     */
    private static int moduleTest() throws Exception {
        Path dir = Files.createTempDirectory("swoft-module-test");
        Files.writeString(dir.resolve("counterlib.sw"), """
                var count = 0
                var label = "hidden"

                export function bump() {
                    set count to count + 1
                }

                export function get_count() {
                    return count
                }

                function secret_prefix() {
                    return "lib:"
                }

                export function labeled() {
                    return "${secret_prefix()}${label}"
                }
                """);
        Path mainEntry = dir.resolve("module_main.sw");
        Files.writeString(mainEntry, """
                import "./counterlib.sw"

                command "modtest" {
                    execute {
                        set count to 999
                        bump()
                        bump()
                        send "module count = ${get_count()}" to sender
                        send "local count = ${count}" to sender
                        send "labeled = ${labeled()}" to sender
                    }
                }
                """);
        Path secondEntry = dir.resolve("module_second.sw");
        Files.writeString(secondEntry, """
                import "./counterlib.sw"

                command "modtest2" {
                    execute {
                        bump()
                        send "second entry count = ${get_count()}" to sender
                    }
                }
                """);

        registerTestProperties();
        FunctionRegistry.clear();
        net.swofty.compiler.ModuleRegistry.clear();

        CapturingSender sender = new CapturingSender();
        for (Path entry : List.of(mainEntry, secondEntry)) {
            ParsedScript parsed = SwoftJsonLoader.load(SwoftcCompiler.compile(entry.toFile()));
            for (SwoftFunction function : parsed.functions()) {
                FunctionRegistry.register(function);
            }
            for (Command command : parsed.commands()) {
                if (command != null && command.getExecuteBlock() != null) {
                    executeBlock(command.getName(), command.getExecuteBlock(), sender);
                }
            }
        }

        List<String> expected = List.of(
                "module count = 2",     // module var mutated through exported functions
                "local count = 999",    // the entry's own 'count' is a separate scope
                "labeled = lib:hidden", // private fn + module var, inside the module
                "second entry count = 3"); // deduped module: one shared registration
        if (!sender.getMessages().equals(expected)) {
            System.err.println("[MODULE] FAIL");
            System.err.println("[MODULE] expected: " + expected);
            System.err.println("[MODULE] actual:   " + sender.getMessages());
            return 1;
        }
        System.out.println("[MODULE] PASS: cross-module calls, module-var privacy, and "
                + "single registration across two entries verified by output");
        return 0;
    }

    private static ParsedScript loadScript(String path) throws Exception {
        File file = new File(path);
        String json = file.getName().endsWith(".json")
                ? Files.readString(file.toPath())
                : SwoftcCompiler.compile(file);
        return SwoftJsonLoader.load(json);
    }

    private static void runAllBlocks(ParsedScript parsed) {
        CapturingSender sender = new CapturingSender();
        for (Command command : parsed.commands()) {
            if (command != null && command.getExecuteBlock() != null) {
                executeBlock(command.getName(), command.getExecuteBlock(), sender);
            }
        }
        for (Event event : parsed.events()) {
            if (event != null && event.getExecuteBlock() != null) {
                executeBlock(event.getName(), event.getExecuteBlock(), sender);
            }
        }

        if (!AsyncRuntime.awaitAll(ASYNC_TIMEOUT_MILLIS)) {
            System.err.println("[HARNESS] timed out waiting for "
                    + AsyncRuntime.taskCount() + " async task(s)");
            AsyncRuntime.cancelAll();
        }
    }

    /**
     * Persistence round-trip: run every execute block TWICE in one JVM
     * with a full PersistStore flush + reload between the rounds, printing
     * cached values and the flushed backend contents each round. Round 2
     * must observe round 1's mutations. Uses the script's declared storage
     * block (temp files dir when absent); an explicit storagePath overrides
     * the files dir / sqlite db path so separate JVM invocations can share
     * one on-disk location (cross-process durability proof). Ends with a
     * keyed-path unit check driving PersistStore with synthetic subject
     * keys (real Player subjects need a Minestom server).
     */
    private static int persistTest(String scriptPath, String storagePath) throws Exception {
        ParsedScript parsed = loadScript(scriptPath);
        if (parsed.persistents().isEmpty()) {
            System.err.println("[PERSIST] script declares no persistent variables");
            return 1;
        }

        registerTestProperties();
        FunctionRegistry.clear();
        for (SwoftFunction function : parsed.functions()) {
            FunctionRegistry.register(function);
        }

        StorageConfigModel config = parsed.storage() != null
                ? parsed.storage()
                : new StorageConfigModel(
                        StorageBackendModel.files(
                                Files.createTempDirectory("swoft-persist-test").toString()),
                        StorageConfigModel.DEFAULT_FLUSH_TICKS);
        if (storagePath != null) {
            StorageBackendModel backend = config.backend();
            if (!backend.kind().equals("files") && !backend.kind().equals("sqlite")) {
                System.err.println("[PERSIST] storage-path override only applies to"
                        + " files/sqlite backends, got '" + backend.kind() + "'");
                return 1;
            }
            config = new StorageConfigModel(
                    new StorageBackendModel(backend.kind(), storagePath, null, 0,
                            null, null, null, null),
                    config.flushTicks());
        }
        System.out.println("[PERSIST] backend '" + config.backend().kind()
                + "' at " + config.backend().path());

        for (int round = 1; round <= 2; round++) {
            System.out.println("[PERSIST] --- round " + round + " ---");
            PersistStore store = PersistStore.initialize(parsed.persistents(), config);

            runAllBlocks(parsed);

            for (Map.Entry<String, Map<String, Object>> var : store.dump().entrySet()) {
                if (var.getValue().isEmpty()) {
                    System.out.println("[PERSIST round " + round + "] "
                            + var.getKey() + ": (no rows)");
                }
                for (Map.Entry<String, Object> row : var.getValue().entrySet()) {
                    String key = row.getKey();
                    System.out.println("[PERSIST round " + round + "] " + var.getKey()
                            + (key.isEmpty() ? "" : "[" + key + "]") + " = " + row.getValue());
                }
            }

            // Full flush + close so round 2 starts from the backend alone
            PersistStore.shutdownActive();

            printBackendContents(config.backend());
        }

        return keyedSyntheticCheck(parsed, config);
    }

    /** Print the flushed rows straight from the backing store. */
    private static void printBackendContents(StorageBackendModel backend) throws Exception {
        switch (backend.kind()) {
            case "files" -> {
                try (var files = Files.list(Path.of(backend.path()))) {
                    for (Path file : files.sorted().toList()) {
                        System.out.println("[PERSIST files] " + file.getFileName()
                                + ": " + Files.readString(file).replace("\n", " ").strip());
                    }
                }
            }
            case "sqlite" -> {
                try (Connection connection =
                                DriverManager.getConnection("jdbc:sqlite:" + backend.path());
                        Statement statement = connection.createStatement();
                        ResultSet rows = statement.executeQuery(
                                "SELECT var, key, value FROM swoft_persist ORDER BY var, key")) {
                    while (rows.next()) {
                        String key = rows.getString(2);
                        System.out.println("[PERSIST sqlite] " + rows.getString(1)
                                + (key.isEmpty() ? "" : "[" + key + "]")
                                + " = " + rows.getString(3));
                    }
                }
            }
            default -> System.out.println("[PERSIST] backend '" + backend.kind()
                    + "' contents not inspected (needs a live server)");
        }
    }

    /**
     * Keyed persistents cannot bind a real Player without a Minestom
     * server, so exercise the keyed path at the PersistStore level with
     * synthetic subject keys: bump each keyed row, flush + close, reload
     * from the backend, and require the bumped values back.
     */
    private static int keyedSyntheticCheck(ParsedScript parsed, StorageConfigModel config) {
        List<PersistentDeclModel> keyed = parsed.persistents().stream()
                .filter(decl -> decl.subject() != null)
                .toList();
        if (keyed.isEmpty()) {
            System.out.println("[PERSIST keyed] no keyed persistents declared - skipping");
            return 0;
        }

        String[] keys = {
            "00000000-0000-0000-0000-000000000001",
            "00000000-0000-0000-0000-000000000002",
        };
        Map<String, Object> expected = new HashMap<>();
        PersistStore store = PersistStore.initialize(parsed.persistents(), config);
        for (PersistentDeclModel decl : keyed) {
            for (String key : keys) {
                Object previous = store.get(decl.name(), key);
                Object next = bump(decl.type(), previous);
                store.set(decl.name(), key, next);
                expected.put(decl.name() + " " + key, next);
                System.out.println("[PERSIST keyed] " + decl.name() + "[" + key + "]: "
                        + previous + " -> " + next);
            }
        }
        PersistStore.shutdownActive();

        // Reload from the backend alone and require every bumped value back
        store = PersistStore.initialize(parsed.persistents(), config);
        int failures = 0;
        for (PersistentDeclModel decl : keyed) {
            for (String key : keys) {
                Object want = expected.get(decl.name() + " " + key);
                Object got = store.get(decl.name(), key);
                if (!want.equals(got)) {
                    System.err.println("[PERSIST keyed] FAIL " + decl.name() + "[" + key
                            + "]: wrote " + want + " but reloaded " + got);
                    failures++;
                }
            }
        }
        PersistStore.shutdownActive();
        System.out.println("[PERSIST keyed] " + (failures == 0
                ? "PASS: " + keyed.size() * keys.length + " keyed row(s) survived flush + reload"
                : failures + " keyed row(s) lost"));
        return failures == 0 ? 0 : 1;
    }

    /**
     * Produce a distinct, type-correct next value for a keyed persistent so the
     * synthetic round-trip both changes and re-reads it. Rich types (Location,
     * Vec, Item, list/map of leaves) must yield a value the store accepts —
     * feeding a String to a Location/Item row would trip the store's coercion
     * guard and abort the whole check, so each type is bumped in kind.
     */
    private static Object bump(net.swofty.nativebridge.representation.DataType type,
            Object previous) {
        return switch (type.getBaseType()) {
            case INTEGER -> (Integer) previous + 1;
            case DOUBLE -> (Double) previous + 0.5;
            case BOOLEAN -> !(Boolean) previous;
            case STRING -> previous + "+";
            case LOCATION -> {
                var p = (net.minestom.server.coordinate.Pos) previous;
                yield p.withCoord(p.x() + 1, p.y(), p.z()).withYaw(p.yaw() + 5f);
            }
            case VEC -> {
                var v = (net.minestom.server.coordinate.Vec) previous;
                yield v.withX(v.x() + 1);
            }
            case ITEM -> {
                var it = (net.minestom.server.item.ItemStack) previous;
                yield it.isAir() ? net.minestom.server.item.ItemStack.of(
                        net.minestom.server.item.Material.STICK, 2)
                        : it.withAmount(it.amount() + 1);
            }
            case LIST -> {
                List<Object> out = new ArrayList<>(
                        previous instanceof List<?> l ? l : List.of());
                out.add(leafSample(type.getSubTypes().isEmpty() ? null
                        : type.getSubTypes().get(0)));
                yield out;
            }
            case MAP -> {
                var m = new net.swofty.runtime.MapValue();
                if (previous instanceof net.swofty.runtime.MapValue prev) {
                    for (var e : prev.snapshot().entrySet()) {
                        m.put(e.getKey(), e.getValue());
                    }
                }
                var subs = type.getSubTypes();
                var valueType = subs.isEmpty() ? null
                        : subs.size() >= 2 ? subs.get(1) : subs.get(0);
                m.put("k" + m.size(), leafSample(valueType));
                yield m;
            }
            case OPTIONAL -> leafSample(type.getSubTypes().isEmpty() ? null
                    : type.getSubTypes().get(0));
            default -> previous + "+";
        };
    }

    /** A concrete sample value for a persistable leaf element type. */
    private static Object leafSample(net.swofty.nativebridge.representation.DataType type) {
        if (type == null) {
            return "x";
        }
        return switch (type.getBaseType()) {
            case INTEGER -> 7;
            case DOUBLE -> 1.5;
            case BOOLEAN -> true;
            case LOCATION -> new net.minestom.server.coordinate.Pos(3, 4, 5, 20f, -8f);
            case VEC -> new net.minestom.server.coordinate.Vec(0.2, 0.3, 0.4);
            case ITEM -> net.minestom.server.item.ItemStack.of(
                    net.minestom.server.item.Material.DIAMOND, 4);
            default -> "x";
        };
    }

    /**
     * Cross-checks the shared OCaml/Java property fixture: every row of
     * compiler/test/property-table.json must resolve in the runtime
     * PropertyRegistry with the same writability.
     */
    private static int checkProps() throws Exception {
        PropertyTables.ensureRegistered();
        Map<String, Class<?>> owners = Map.ofEntries(
                Map.entry("Player", net.minestom.server.entity.Player.class),
                Map.entry("Location", net.minestom.server.coordinate.Pos.class),
                // phase-7 owners (entity system)
                Map.entry("Entity", net.minestom.server.entity.Entity.class),
                Map.entry("Vec", net.minestom.server.coordinate.Vec.class),
                Map.entry("Item", net.minestom.server.item.ItemStack.class),
                Map.entry("Mob", net.swofty.mobs.SwoftMob.class),
                // phase-6 owners (design 6B/6D)
                Map.entry("World", net.minestom.server.instance.Instance.class),
                Map.entry("Display", net.swofty.displays.SwoftDisplay.class),
                Map.entry("Request", net.swofty.http.SwoftHttpRequest.class),
                Map.entry("Song", net.swofty.music.NbsSong.class),
                Map.entry("Server", net.swofty.runtime.ServerValue.class),
                Map.entry("Skin", net.minestom.server.entity.PlayerSkin.class),
                Map.entry("Canvas", net.swofty.maps.MapCanvas.class),
                Map.entry("Schedule", net.swofty.sched.ScheduleHandle.class),
                Map.entry("event:PlayerChat", SwoftPlayerChatEvent.class),
                Map.entry("event:PlayerJoin", SwoftPlayerJoinEvent.class),
                Map.entry("event:PlayerUseItem",
                        net.swofty.event.events.SwoftPlayerUseItemEvent.class),
                Map.entry("event:MobSpawn", net.swofty.event.events.SwoftMobSpawnEvent.class),
                Map.entry("event:MobDeath", net.swofty.event.events.SwoftMobDeathEvent.class),
                Map.entry("event:MobDamage", net.swofty.event.events.SwoftMobDamageEvent.class),
                Map.entry("event:TpsChange",
                        net.swofty.event.events.SwoftTpsChangeEvent.class),
                Map.entry("event:BlockBreak",
                        net.swofty.event.events.SwoftBlockBreakEvent.class),
                Map.entry("event:BlockPlace",
                        net.swofty.event.events.SwoftBlockPlaceEvent.class),
                Map.entry("event:ServerPing",
                        net.swofty.event.events.SwoftServerPingEvent.class),
                // phase-8 owners (offline players + fishing events)
                Map.entry("OfflinePlayer", net.swofty.players.OfflinePlayerValue.class),
                Map.entry("event:PlayerCastRod",
                        net.swofty.event.events.SwoftPlayerCastRodEvent.class),
                Map.entry("event:FishBite",
                        net.swofty.event.events.SwoftFishBiteEvent.class),
                Map.entry("event:PlayerCatchFish",
                        net.swofty.event.events.SwoftPlayerCatchFishEvent.class),
                Map.entry("event:PlayerReelIn",
                        net.swofty.event.events.SwoftPlayerReelInEvent.class),
                // phase-9 owner (dispenser runtime)
                Map.entry("event:BlockDispense",
                        net.swofty.event.events.SwoftBlockDispenseEvent.class),
                // phase-10 owner (command preprocess event)
                Map.entry("event:PlayerCommand",
                        net.swofty.event.events.SwoftPlayerCommandEvent.class));

        String json = Files.readString(Path.of("compiler/test/property-table.json"));
        int rows = 0;
        int failures = 0;
        for (JsonElement element : JsonParser.parseString(json).getAsJsonArray()) {
            rows++;
            JsonObject row = element.getAsJsonObject();
            String owner = row.get("owner").getAsString();
            String name = row.get("name").getAsString();
            boolean writable = row.get("writable").getAsBoolean();

            Class<?> ownerClass = owners.get(owner);
            if (ownerClass == null) {
                System.err.println("[CHECK] no Java class mapping for owner '" + owner + "'");
                failures++;
                continue;
            }
            var def = PropertyRegistry.lookup(ownerClass, name);
            if (def.isEmpty()) {
                System.err.println("[CHECK] " + owner + "." + name
                        + " missing from PropertyRegistry (looked up on "
                        + ownerClass.getName() + ")");
                failures++;
                continue;
            }
            boolean actual = def.get().isSettable()
                    || (def.get().isCopyHop() && !def.get().passThroughOnly());
            if (actual != writable) {
                System.err.println("[CHECK] " + owner + "." + name
                        + " writability mismatch: fixture=" + writable + " registry=" + actual);
                failures++;
            }
        }
        System.out.println("[CHECK] property-table: " + rows + " row(s), "
                + failures + " mismatch(es)");
        return failures == 0 ? 0 : 1;
    }

    private static void executeBlock(String name, ExecuteBlock block, CapturingSender sender) {
        System.out.println("[EXEC] " + name);
        Map<String, Object> variables = new HashMap<>();
        variables.put("thing", new TestThing("widget", 0, new TestPoint(1.0, 2.0)));
        try {
            ASTExecutor executor = new ASTExecutor(sender, variables);
            if (block.isAsync()) {
                AsyncRuntime.start("harness " + name, () -> executor.execute(block));
            } else {
                executor.execute(block);
            }
        } catch (Exception e) {
            System.err.println("Error executing " + name + ": " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Serverless property table: TestThing is a mutable anchor, TestPoint an
     * immutable value type reached through withers (point is TICK so the
     * anchor+wither write also exercises the TickDispatch passthrough)
     */
    private static void registerTestProperties() {
        PropertyRegistry.register(PropertyDef.of("name", TestThing.class,
                TestThing::getName,
                (thing, value) -> thing.setName((String) value),
                null, Coercions::toStringValue, ThreadPolicy.ANY));
        PropertyRegistry.register(PropertyDef.of("score", TestThing.class,
                TestThing::getScore,
                (thing, value) -> thing.setScore((Integer) value),
                null, Coercions::toInt, ThreadPolicy.ANY));
        PropertyRegistry.register(PropertyDef.of("point", TestThing.class,
                TestThing::getPoint,
                (thing, value) -> thing.setPoint((TestPoint) value),
                null, value -> {
                    if (value instanceof TestPoint point) {
                        return point;
                    }
                    throw new net.swofty.ScriptError("expected a point, got: " + value);
                }, ThreadPolicy.TICK));
        PropertyRegistry.register(PropertyDef.of("x", TestPoint.class,
                TestPoint::x, null,
                (point, value) -> point.withX((Double) value),
                Coercions::toDouble, ThreadPolicy.ANY));
        PropertyRegistry.register(PropertyDef.of("y", TestPoint.class,
                TestPoint::y, null,
                (point, value) -> point.withY((Double) value),
                Coercions::toDouble, ThreadPolicy.ANY));
    }

    /**
     * Mutable harness object with a wither-only nested value
     */
    public static final class TestThing {
        private String name;
        private int score;
        private TestPoint point;

        public TestThing(String name, int score, TestPoint point) {
            this.name = name;
            this.score = score;
            this.point = point;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public int getScore() {
            return score;
        }

        public void setScore(int score) {
            this.score = score;
        }

        public TestPoint getPoint() {
            return point;
        }

        public void setPoint(TestPoint point) {
            this.point = point;
        }

        @Override
        public String toString() {
            return "TestThing(" + name + ", " + score + ", " + point + ")";
        }
    }

    /**
     * Immutable value type: writes go through withers back to the anchor
     */
    public record TestPoint(double x, double y) {
        public TestPoint withX(double x) {
            return new TestPoint(x, y);
        }

        public TestPoint withY(double y) {
            return new TestPoint(x, y);
        }

        @Override
        public String toString() {
            return "(" + x + ", " + y + ")";
        }
    }

    /**
     * Minimal CommandSender that records and echoes every message
     */
    static class CapturingSender implements CommandSender {
        private final List<String> messages = new ArrayList<>();

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

        public List<String> getMessages() {
            return messages;
        }

        @Override
        public @NotNull Identity identity() {
            return Identity.nil();
        }

        @Override
        public @NotNull TagHandler tagHandler() {
            return TagHandler.newHandler();
        }

        @Override
        public String toString() {
            return "Harness";
        }
    }
}
