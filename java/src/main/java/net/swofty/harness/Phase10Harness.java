package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.Player;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.player.PlayerCommandEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.minestom.server.tag.Tag;
import net.swofty.ASTExecutor;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.event.EventRegistrar;
import net.swofty.model.PersistentDeclModel;
import net.swofty.model.StorageBackendModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.execution.Statement;
import net.swofty.compiler.SwoftFunction;
import net.swofty.nativebridge.execution.commands.ForEachStatement;
import net.swofty.nativebridge.execution.commands.IndexAssignStatement;
import net.swofty.nativebridge.execution.commands.ReturnStatement;
import net.swofty.nativebridge.execution.expressions.FunctionCallExpression;
import net.swofty.nativebridge.execution.expressions.IndexExpression;
import net.swofty.nativebridge.execution.expressions.LambdaExpression;
import net.swofty.nativebridge.execution.expressions.NoneLiteral;
import net.swofty.nativebridge.execution.expressions.NumberLiteral;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.BaseType;
import net.swofty.nativebridge.representation.DataType;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.persist.PersistStore;
import net.swofty.props.NoneValue;
import net.swofty.props.PropertyDef;
import net.swofty.props.PropertyRegistry;
import net.swofty.props.PropertyTables;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.MapValue;
import net.swofty.runtime.Values;

/**
 * Serverless phase-10 coverage (design phase-10 §1-§5). Two entry points:
 *
 * <ul>
 * <li>{@link #mapTest()} drives the map runtime (get/set/has/delete/keys/
 *     size/foreach/index) through the real script machinery - builtins are
 *     called as FunctionCallExpressions, index reads/writes as the loader's
 *     IndexExpression/IndexAssignStatement, entry loops as ForEachStatement -
 *     then round-trips a persistent map&lt;Integer&gt; through a files backend
 *     with a simulated restart (init -&gt; write -&gt; shutdown -&gt; re-init
 *     reads the whole-map JSON blob back).</li>
 * <li>{@link #smoke()} exercises pose, weather, the PlayerCommand veto (fired
 *     synthetically down the real EventRegistrar path) and item &lt;-&gt; NBT
 *     round-trips against live Minestom objects.</li>
 * </ul>
 */
public final class Phase10Harness {

    private Phase10Harness() {
    }

    // ------------------------------------------------------------------
    // --map-test : map runtime + persistence
    // ------------------------------------------------------------------

    public static int mapTest() throws Exception {
        PropertyTables.ensureRegistered();
        int failures = 0;
        failures += mapBuiltins();
        failures += mapIntKeys();
        failures += mapPersistRoundTrip();
        failures += mapIntPersistRoundTrip();
        failures += mapConcurrentFlush();
        System.out.println(failures == 0
                ? "[PHASE10 map] ALL PASSED"
                : "[PHASE10 map] " + failures + " FAILURE(S)");
        return failures == 0 ? 0 : 1;
    }

    private static int mapBuiltins() {
        int failures = 0;
        ASTExecutor executor = new ASTExecutor(null, new HashMap<>());
        ExecutionContext ctx = executor.context();

        // new_map() -> empty MapValue, bound to script variable m
        Object created = executor.evaluateExpression(call("new_map"));
        failures += expect("new_map is a map", created instanceof MapValue);
        ctx.getVariables().put("m", created);

        // map_set / map_size / map_has / map_get
        executor.evaluateExpression(call("map_set", var("m"), str("apple"), num(1)));
        executor.evaluateExpression(call("map_set", var("m"), str("banana"), num(2)));
        executor.evaluateExpression(call("map_set", var("m"), str("cherry"), num(3)));
        failures += expect("size 3",
                eq(executor.evaluateExpression(call("map_size", var("m"))), 3));
        failures += expect("has apple",
                Boolean.TRUE.equals(executor.evaluateExpression(
                        call("map_has", var("m"), str("apple")))));
        failures += expect("no durian",
                Boolean.FALSE.equals(executor.evaluateExpression(
                        call("map_has", var("m"), str("durian")))));
        failures += expect("get banana = 2",
                eq(executor.evaluateExpression(call("map_get", var("m"), str("banana"))), 2));
        failures += expect("get missing = none",
                NoneValue.isNone(executor.evaluateExpression(
                        call("map_get", var("m"), str("durian")))));

        // map_keys is a fresh insertion-ordered list snapshot
        Object keys = executor.evaluateExpression(call("map_keys", var("m")));
        failures += expect("keys ordered [apple,banana,cherry]",
                keys instanceof List<?> l
                        && l.equals(List.of("apple", "banana", "cherry")));

        // index read: m["cherry"] == 3
        failures += expect("m[\"cherry\"] = 3",
                eq(executor.evaluateExpression(index(var("m"), str("cherry"))), 3));
        failures += expect("m[\"missing\"] = none",
                NoneValue.isNone(executor.evaluateExpression(index(var("m"), str("durian")))));

        // index assign: set m["banana"] to 20
        ctx.execute(setIndex(var("m"), str("banana"), num(20)));
        failures += expect("m[\"banana\"] now 20",
                eq(executor.evaluateExpression(call("map_get", var("m"), str("banana"))), 20));

        // storing none deletes the row (map_set + index-assign both honour it)
        ctx.execute(setIndex(var("m"), str("apple"), none()));
        failures += expect("apple deleted via set none",
                Boolean.FALSE.equals(executor.evaluateExpression(
                        call("map_has", var("m"), str("apple")))));
        executor.evaluateExpression(call("map_delete", var("m"), str("cherry")));
        failures += expect("cherry deleted, size 1",
                eq(executor.evaluateExpression(call("map_size", var("m"))), 1));

        // mutable reference: a second handle sees the same underlying map
        ctx.getVariables().put("alias", created);
        executor.evaluateExpression(call("map_set", var("alias"), str("date"), num(9)));
        failures += expect("alias write visible through m",
                eq(executor.evaluateExpression(call("map_get", var("m"), str("date"))), 9));

        // foreach: loop m as k -> v (insertion order banana=20, date=9)
        List<String> visited = new ArrayList<>();
        Statement record = new Statement() {
            @Override
            public void execute(ExecutionContext c) {
                visited.add(c.getVariables().get("k") + "="
                        + Values.displayString(c.getVariables().get("v")));
            }
        };
        ctx.execute(new ForEachStatement("k", "v", var("m"), null, record));
        failures += expect("foreach entries [banana=20, date=9]",
                visited.equals(List.of("banana=20", "date=9")));

        // loop m as k (key-only over a map)
        List<String> keysOnly = new ArrayList<>();
        Statement recordKey = new Statement() {
            @Override
            public void execute(ExecutionContext c) {
                keysOnly.add(String.valueOf(c.getVariables().get("k")));
            }
        };
        ctx.execute(new ForEachStatement("k", var("m"), null, recordKey));
        failures += expect("key-only foreach [banana, date]",
                keysOnly.equals(List.of("banana", "date")));

        // is a Map
        failures += expect("is a Map", Values.isType(created, "Map"));
        return failures;
    }

    /**
     * Integer-keyed maps (collections pass): get/set/has/delete/keys-order/
     * index/foreach all accept Integer keys, keys stay Integer (never
     * stringified), and a String key is a DISTINCT miss (no cross-coercion).
     */
    private static int mapIntKeys() {
        int failures = 0;
        ASTExecutor executor = new ASTExecutor(null, new HashMap<>());
        ExecutionContext ctx = executor.context();

        Object created = executor.evaluateExpression(call("new_map"));
        ctx.getVariables().put("m", created);

        executor.evaluateExpression(call("map_set", var("m"), num(1), str("one")));
        executor.evaluateExpression(call("map_set", var("m"), num(2), str("two")));
        executor.evaluateExpression(call("map_set", var("m"), num(3), str("three")));

        failures += expect("int map size 3",
                eq(executor.evaluateExpression(call("map_size", var("m"))), 3));
        failures += expect("has int key 2",
                Boolean.TRUE.equals(executor.evaluateExpression(
                        call("map_has", var("m"), num(2)))));
        failures += expect("get int key 2 = two",
                "two".equals(executor.evaluateExpression(
                        call("map_get", var("m"), num(2)))));

        // a String "2" must NOT hit the Integer key 2 (keys are not coerced)
        failures += expect("string \"2\" misses int key 2",
                NoneValue.isNone(executor.evaluateExpression(
                        call("map_get", var("m"), str("2")))));

        // map_keys returns an Integer list in insertion order
        Object keys = executor.evaluateExpression(call("map_keys", var("m")));
        failures += expect("int keys are Integer list [1,2,3]",
                keys instanceof List<?> l && l.equals(List.of(1, 2, 3)));
        failures += expect("first key is an Integer instance",
                keys instanceof List<?> l && !l.isEmpty() && l.get(0) instanceof Integer);

        // index read + index assign with an Integer key
        failures += expect("m[2] = two",
                "two".equals(executor.evaluateExpression(index(var("m"), num(2)))));
        ctx.execute(setIndex(var("m"), num(2), str("TWO")));
        failures += expect("m[2] now TWO",
                "TWO".equals(executor.evaluateExpression(
                        call("map_get", var("m"), num(2)))));

        // delete by Integer key
        executor.evaluateExpression(call("map_delete", var("m"), num(1)));
        failures += expect("after delete int key 1, size 2",
                eq(executor.evaluateExpression(call("map_size", var("m"))), 2));

        // foreach binds the Integer key
        List<String> visited = new ArrayList<>();
        Statement record = new Statement() {
            @Override
            public void execute(ExecutionContext c) {
                Object k = c.getVariables().get("k");
                visited.add((k instanceof Integer ? "int:" : "?:") + k + "="
                        + Values.displayString(c.getVariables().get("v")));
            }
        };
        ctx.execute(new ForEachStatement("k", "v", var("m"), null, record));
        failures += expect("int-key foreach [int:2=TWO, int:3=three]",
                visited.equals(List.of("int:2=TWO", "int:3=three")));
        return failures;
    }

    private static int mapPersistRoundTrip() throws Exception {
        int failures = 0;
        Path dir = Files.createTempDirectory("swoft-phase10-map");
        DataType mapType = new DataType(BaseType.MAP);
        mapType.addSubType(new DataType(BaseType.INTEGER));
        PersistentDeclModel decl = new PersistentDeclModel(
                "scores", null, mapType, call("new_map"), 0, 0);
        StorageConfigModel config = new StorageConfigModel(
                StorageBackendModel.files(dir.toString()),
                StorageConfigModel.DEFAULT_FLUSH_TICKS);

        // round 1: write two rows into a global map, plus a per-subject map
        PersistStore store = PersistStore.initialize(List.of(decl), config);
        MapValue global = new MapValue();
        global.put("alice", 5);
        global.put("bob", 3);
        store.set("scores", "", global);
        MapValue perSubject = new MapValue();
        perSubject.put("wins", 7);
        store.set("scores", "team-red", perSubject);
        PersistStore.shutdownActive();

        String blob = Files.readString(dir.resolve("scores.json"));
        System.out.println("[PHASE10 map] persisted blob: " + blob);
        failures += expect("blob is a whole-map JSON object",
                blob.contains("\"alice\":5") && blob.contains("\"bob\":3")
                        && blob.contains("\"wins\":7"));

        // round 2: simulated restart - a fresh store reads from the backend
        PersistStore restarted = PersistStore.initialize(List.of(decl), config);
        Object reloaded = restarted.get("scores", "");
        failures += expect("reloaded global is a map", reloaded instanceof MapValue);
        if (reloaded instanceof MapValue m) {
            failures += expect("alice survived restart = 5", eq(m.get("alice"), 5));
            failures += expect("bob survived restart = 3", eq(m.get("bob"), 3));
        }
        Object reloadedSubject = restarted.get("scores", "team-red");
        failures += expect("per-subject map survived restart",
                reloadedSubject instanceof MapValue msub && eq(msub.get("wins"), 7));

        // absent subject reads a FRESH empty map, never the shared default
        Object absentA = restarted.get("scores", "team-blue");
        Object absentB = restarted.get("scores", "team-green");
        failures += expect("absent map row is empty",
                absentA instanceof MapValue e && e.isEmpty());
        failures += expect("absent rows are distinct copies (not shared default)",
                absentA != absentB);
        PersistStore.shutdownActive();
        return failures;
    }

    /**
     * A persistent {@code map<Integer, String>} keyed by 1,2,3 survives a
     * flush + simulated restart with its keys reloaded as boxed Integer (not
     * the "1"/"2"/"3" JSON strings): the store serializes Integer keys as
     * decimal strings and coerces them back per the declared key type.
     */
    private static int mapIntPersistRoundTrip() throws Exception {
        int failures = 0;
        Path dir = Files.createTempDirectory("swoft-phase10-intmap");
        // map<Integer, String>: [K=Integer, V=String] subtype shape
        DataType mapType = new DataType(BaseType.MAP);
        mapType.addSubType(new DataType(BaseType.INTEGER));
        mapType.addSubType(new DataType(BaseType.STRING));
        PersistentDeclModel decl = new PersistentDeclModel(
                "labels", null, mapType, call("new_map"), 0, 0);
        StorageConfigModel config = new StorageConfigModel(
                StorageBackendModel.files(dir.toString()),
                StorageConfigModel.DEFAULT_FLUSH_TICKS);

        PersistStore store = PersistStore.initialize(List.of(decl), config);
        MapValue labels = new MapValue();
        labels.put(1, "one");
        labels.put(2, "two");
        labels.put(3, "three");
        store.set("labels", "", labels);
        PersistStore.shutdownActive();

        String blob = Files.readString(dir.resolve("labels.json"));
        System.out.println("[PHASE10 map] int-keyed blob: " + blob);
        failures += expect("int-keyed blob serializes keys as strings",
                blob.contains("\"1\":\"one\"") && blob.contains("\"2\":\"two\"")
                        && blob.contains("\"3\":\"three\""));

        PersistStore restarted = PersistStore.initialize(List.of(decl), config);
        Object reloaded = restarted.get("labels", "");
        failures += expect("reloaded int map is a map", reloaded instanceof MapValue);
        if (reloaded instanceof MapValue r) {
            failures += expect("keys reload as Integer (not string \"1\"/\"2\"/\"3\")",
                    r.containsKey(1) && r.containsKey(2) && r.containsKey(3)
                            && !r.containsKey("1") && !r.containsKey("2")
                            && !r.containsKey("3"));
            failures += expect("get(2 as Integer) = two", "two".equals(r.get(2)));
            Object firstKey = r.keySet().iterator().next();
            failures += expect("a reloaded key is an Integer instance",
                    firstKey instanceof Integer);
            failures += expect("insertion order preserved [1,2,3]",
                    new ArrayList<>(r.keySet()).equals(List.of(1, 2, 3)));
        }
        PersistStore.shutdownActive();
        return failures;
    }

    /**
     * Regression for the flush-loop CME: the blessed mutation path hands a
     * script the LIVE cached map and mutates it in place (map_set -&gt;
     * MapValue.put) on the tick thread while the flush thread serializes the
     * same row. Before the fix, toJson iterated the live map and any
     * concurrent put/remove threw ConcurrentModificationException, which
     * escaped flush() and permanently killed the flush virtual thread. Here a
     * mutator thread hammers put/remove on the live row while this thread
     * drives flush() repeatedly; the fix (snapshot under the map's monitor)
     * must let every cycle complete without a throwable escaping.
     */
    private static int mapConcurrentFlush() throws Exception {
        int failures = 0;
        Path dir = Files.createTempDirectory("swoft-phase10-cme");
        DataType mapType = new DataType(BaseType.MAP);
        mapType.addSubType(new DataType(BaseType.INTEGER));
        PersistentDeclModel decl = new PersistentDeclModel(
                "scores", null, mapType, call("new_map"), 0, 0);
        StorageConfigModel config = new StorageConfigModel(
                StorageBackendModel.files(dir.toString()),
                StorageConfigModel.DEFAULT_FLUSH_TICKS);
        PersistStore store = PersistStore.initialize(List.of(decl), config);

        MapValue live = new MapValue();
        store.set("scores", "", live);
        // premise of the finding: a present row hands back the LIVE reference,
        // so a script mutation is a mutation of the cached (flushed) instance
        failures += expect("get() returns the live cached map (finding premise)",
                store.get("scores", "") == live);

        final java.util.concurrent.atomic.AtomicReference<Throwable> flushError =
                new java.util.concurrent.atomic.AtomicReference<>();
        final java.util.concurrent.atomic.AtomicBoolean go =
                new java.util.concurrent.atomic.AtomicBoolean(true);

        Thread mutator = new Thread(() -> {
            int i = 0;
            while (go.get()) {
                String key = "k" + (i % 64);
                if ((i & 1) == 0) {
                    live.put(key, i);               // map_set path
                } else {
                    live.remove(key);               // map_delete path
                }
                store.set("scores", "", live);      // re-mark the row dirty
                i++;
            }
        }, "phase10-cme-mutator");
        mutator.start();

        for (int cycle = 0; cycle < 4000 && flushError.get() == null; cycle++) {
            try {
                store.flush();
            } catch (Throwable t) {
                flushError.set(t);
            }
        }
        go.set(false);
        mutator.join(2000);

        Throwable err = flushError.get();
        failures += expect("no exception escapes flush() under concurrent mutation",
                err == null);
        if (err != null) {
            err.printStackTrace();
        }
        // the flush loop must still be alive: one more flush persists the final
        // state, and a restart must read a well-formed whole-map blob back
        PersistStore.shutdownActive();
        String blob = Files.readString(dir.resolve("scores.json"));
        // {"":{"k0":0,"k2":2,...}} - the empty global row wrapping the map blob
        failures += expect("post-stress blob is a valid whole-map JSON object",
                blob.trim().startsWith("{") && blob.contains("\"k"));
        return failures;
    }

    // ------------------------------------------------------------------
    // --phase10-smoke : pose / weather / command / nbt
    // ------------------------------------------------------------------

    public static int smoke() throws Exception {
        if (MinecraftServer.process() == null) {
            MinecraftServer.init();
        }
        PropertyTables.ensureRegistered();
        int failures = 0;
        failures += poseSmoke();
        failures += weatherSmoke();
        failures += commandSmoke();
        failures += nbtSmoke();
        System.out.println(failures == 0
                ? "[PHASE10 smoke] ALL PASSED"
                : "[PHASE10 smoke] " + failures + " FAILURE(S)");
        return failures == 0 ? 0 : 1;
    }

    private static int poseSmoke() {
        int failures = 0;
        Entity warden = new Entity(EntityType.WARDEN);
        PropertyDef pose = PropertyRegistry.lookup(Entity.class, "pose").orElseThrow();

        writeProp(pose, warden, "sniffing");
        failures += expect("pose set to sniffing",
                warden.getPose() == net.minestom.server.entity.EntityPose.SNIFFING);
        failures += expect("pose reads back sniffing",
                "sniffing".equals(pose.getter().apply(warden)));

        writeProp(pose, warden, "spin_attack");
        failures += expect("snake_case pose spin_attack -> SPIN_ATTACK",
                warden.getPose() == net.minestom.server.entity.EntityPose.SPIN_ATTACK);

        boolean rejected = false;
        try {
            pose.coercion().apply("moonwalk");
        } catch (ScriptError e) {
            rejected = true;
        }
        failures += expect("invalid pose rejected", rejected);

        // sneaking convenience row (also on Entity, so mobs inherit it)
        PropertyDef sneaking = PropertyRegistry.lookup(Entity.class, "sneaking").orElseThrow();
        writeProp(sneaking, warden, true);
        failures += expect("sneaking true", warden.isSneaking());
        failures += expect("sneaking reads back true",
                Boolean.TRUE.equals(sneaking.getter().apply(warden)));
        return failures;
    }

    private static int weatherSmoke() {
        int failures = 0;
        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setChunkSupplier(net.minestom.server.instance.LightingChunk::new);
        PropertyDef weather = PropertyRegistry.lookup(
                net.minestom.server.instance.Instance.class, "weather").orElseThrow();
        PropertyDef raining = PropertyRegistry.lookup(
                net.minestom.server.instance.Instance.class, "raining").orElseThrow();
        PropertyDef thundering = PropertyRegistry.lookup(
                net.minestom.server.instance.Instance.class, "thundering").orElseThrow();

        writeProp(weather, instance, "thunder");
        failures += expect("weather=thunder reads thunder",
                "thunder".equals(weather.getter().apply(instance)));
        failures += expect("thunder is raining", Boolean.TRUE.equals(raining.getter().apply(instance)));
        failures += expect("thunder is thundering",
                Boolean.TRUE.equals(thundering.getter().apply(instance)));

        writeProp(weather, instance, "rain");
        failures += expect("weather=rain reads rain",
                "rain".equals(weather.getter().apply(instance)));
        failures += expect("rain is raining", Boolean.TRUE.equals(raining.getter().apply(instance)));
        failures += expect("rain not thundering",
                Boolean.FALSE.equals(thundering.getter().apply(instance)));

        writeProp(weather, instance, "clear");
        failures += expect("weather=clear reads clear",
                "clear".equals(weather.getter().apply(instance)));
        failures += expect("clear not raining",
                Boolean.FALSE.equals(raining.getter().apply(instance)));

        boolean rejected = false;
        try {
            weather.coercion().apply("hurricane");
        } catch (ScriptError e) {
            rejected = true;
        }
        failures += expect("invalid weather rejected", rejected);
        return failures;
    }

    private static int commandSmoke() throws Exception {
        int failures = 0;
        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setChunkSupplier(net.minestom.server.instance.LightingChunk::new);
        instance.setBlock(0, 40, 0, Block.STONE);

        FakeConnection wire = new FakeConnection();
        Player player = new Player(wire, new GameProfile(UUID.randomUUID(), "Admin"));
        var joined = player.setInstance(instance, new Pos(0.5, 41, 0.5));
        for (int t = 0; t < 100 && !joined.isDone(); t++) {
            Thread.sleep(10);
        }

        // (1) wrapper rows read/rewrite the underlying command, cancel vetoes
        PlayerCommandEvent direct = new PlayerCommandEvent(player, "spawn");
        var wrapper = new net.swofty.event.events.SwoftPlayerCommandEvent(
                direct, new Event("PlayerCommand"));
        failures += expect("command row reads 'spawn'", "spawn".equals(wrapper.getCommand()));
        wrapper.setCommand("home");
        failures += expect("command rewrite propagates to Minestom event",
                "home".equals(direct.getCommand()));
        wrapper.setCancelled(true);
        failures += expect("cancel propagates to the Minestom event (veto)",
                direct.isCancelled());

        // (2) full path: register a curated PlayerCommand handler through the
        // real EventRegistrar and fire the event synthetically down the
        // command path (EventDispatcher). The handler cancels op attempts.
        Event scriptEvent = new Event("PlayerCommand");
        ExecuteBlock block = new ExecuteBlock();
        block.addStatement(new Statement() {
            @Override
            public void execute(ExecutionContext c) {
                var ev = (net.swofty.event.events.SwoftPlayerCommandEvent)
                        c.getVariables().get("event");
                if (ev.getCommand().startsWith("op ")) {
                    ev.setCancelled(true);
                }
            }
        });
        scriptEvent.setExecuteBlock(block);
        new EventRegistrar().registerEvent(scriptEvent);

        PlayerCommandEvent opAttempt = new PlayerCommandEvent(player, "op Admin");
        EventDispatcher.call(opAttempt);
        failures += expect("script vetoed 'op Admin' pre-dispatch", opAttempt.isCancelled());

        PlayerCommandEvent allowed = new PlayerCommandEvent(player, "spawn");
        EventDispatcher.call(allowed);
        failures += expect("'spawn' left uncancelled", !allowed.isCancelled());
        return failures;
    }

    private static int nbtSmoke() {
        int failures = 0;
        ASTExecutor executor = new ASTExecutor(null, new HashMap<>());
        ExecutionContext ctx = executor.context();

        // an item with a stacked amount + a nested custom tag tree
        ItemStack item = ItemStack.of(Material.DIAMOND_SWORD, 5)
                .withTag(Tag.String("owner"), "Steve")
                .withTag(Tag.Integer("level"), 42);
        ctx.getVariables().put("it", item);

        Object snbt = executor.evaluateExpression(call("to_nbt", var("it")));
        failures += expect("to_nbt returns a string", snbt instanceof String);
        System.out.println("[PHASE10 smoke] item SNBT: " + snbt);

        Object restored = executor.evaluateExpression(
                call("from_nbt", str(String.valueOf(snbt))));
        failures += expect("from_nbt returns an item", restored instanceof ItemStack);
        if (restored instanceof ItemStack back) {
            failures += expect("material round-trips", back.material() == Material.DIAMOND_SWORD);
            failures += expect("amount round-trips", back.amount() == 5);
            failures += expect("nested string tag round-trips",
                    "Steve".equals(back.getTag(Tag.String("owner"))));
            failures += expect("nested int tag round-trips",
                    Integer.valueOf(42).equals(back.getTag(Tag.Integer("level"))));
        }

        // malformed SNBT -> none (parse-back is total)
        Object bad = executor.evaluateExpression(call("from_nbt", str("{not valid nbt")));
        failures += expect("malformed nbt -> none", NoneValue.isNone(bad));
        return failures;
    }

    // ------------------------------------------------------------------
    // --collections-test : sorting + random + numeric-aware equality
    // ------------------------------------------------------------------

    public static int collectionsTest() {
        int failures = 0;
        failures += sortLists();
        failures += sortMaps();
        failures += equalityChecks();
        failures += randomChecks();
        System.out.println(failures == 0
                ? "[COLLECTIONS] ALL PASSED"
                : "[COLLECTIONS] " + failures + " FAILURE(S)");
        return failures == 0 ? 0 : 1;
    }

    private static int sortLists() {
        int failures = 0;
        ASTExecutor executor = new ASTExecutor(null, new HashMap<>());
        ExecutionContext ctx = executor.context();

        // natural numeric sort, non-mutating
        ctx.getVariables().put("nums", listVal(3, 1, 2, 10, 5));
        Object sorted = executor.evaluateExpression(call("sort", var("nums")));
        failures += expect("sort numbers ascending [1,2,3,5,10]",
                sorted instanceof List<?> l && l.equals(List.of(1, 2, 3, 5, 10)));
        failures += expect("sort is non-mutating (original intact)",
                ctx.getVariables().get("nums").equals(listVal(3, 1, 2, 10, 5)));

        // natural lexicographic string sort
        ctx.getVariables().put("words", listVal("cherry", "apple", "banana"));
        Object words = executor.evaluateExpression(call("sort", var("words")));
        failures += expect("sort strings lexicographic",
                words instanceof List<?> l && l.equals(List.of("apple", "banana", "cherry")));

        // reverse copy
        Object rev = executor.evaluateExpression(call("reverse", var("nums")));
        failures += expect("reverse copy",
                rev instanceof List<?> l && l.equals(List.of(5, 10, 2, 1, 3)));

        // leaderboard: sort_by_desc over players by "kills"
        ctx.getVariables().put("players", listVal(
                player("alice", 5), player("bob", 12), player("carol", 8)));
        LambdaExpression byKills = keyLambda("p", index(var("p"), str("kills")));
        Object top = executor.evaluateExpression(
                call("sort_by_desc", var("players"), byKills));
        failures += expect("sort_by_desc leaderboard [bob,carol,alice]",
                names(top).equals(List.of("bob", "carol", "alice")));
        Object asc = executor.evaluateExpression(
                call("sort_by", var("players"), keyLambda("p", index(var("p"), str("kills")))));
        failures += expect("sort_by ascending [alice,carol,bob]",
                names(asc).equals(List.of("alice", "carol", "bob")));

        // stable ties: equal keys keep input order
        ctx.getVariables().put("tied", listVal(
                player("x", 1), player("y", 1), player("z", 1)));
        Object stable = executor.evaluateExpression(
                call("sort_by", var("tied"), keyLambda("p", index(var("p"), str("kills")))));
        failures += expect("stable sort preserves tie order [x,y,z]",
                names(stable).equals(List.of("x", "y", "z")));

        // max_by / min_by without a full sort
        Object best = executor.evaluateExpression(
                call("max_by", var("players"), keyLambda("p", index(var("p"), str("kills")))));
        failures += expect("max_by is bob",
                best instanceof MapValue m && "bob".equals(m.get("name")));
        Object worst = executor.evaluateExpression(
                call("min_by", var("players"), keyLambda("p", index(var("p"), str("kills")))));
        failures += expect("min_by is alice",
                worst instanceof MapValue m && "alice".equals(m.get("name")));

        // empty list: sort -> [], min/max_by -> none
        ctx.getVariables().put("empty", listVal());
        Object emptySorted = executor.evaluateExpression(call("sort", var("empty")));
        failures += expect("sort empty -> []",
                emptySorted instanceof List<?> l && l.isEmpty());
        Object emptyMax = executor.evaluateExpression(
                call("max_by", var("empty"), keyLambda("p", index(var("p"), str("kills")))));
        failures += expect("max_by empty -> none", NoneValue.isNone(emptyMax));

        // map_keys + sort_by composition also produces a ranked list
        ctx.getVariables().put("scores", mapVal(
                entry("alice", 5), entry("bob", 12), entry("carol", 8)));
        Object rankedKeys = executor.evaluateExpression(
                call("sort_by_desc", call("map_keys", var("scores")),
                        keyLambda("k", index(var("scores"), var("k")))));
        failures += expect("map_keys + sort_by_desc ranked [bob,carol,alice]",
                rankedKeys instanceof List<?> l && l.equals(List.of("bob", "carol", "alice")));
        return failures;
    }

    private static int sortMaps() {
        int failures = 0;
        ASTExecutor executor = new ASTExecutor(null, new HashMap<>());
        ExecutionContext ctx = executor.context();

        ctx.getVariables().put("scores", mapVal(
                entry("alice", 5), entry("bob", 12), entry("carol", 8)));

        // sort_by_value_desc: highest first, iterate in that order (NEW map)
        Object ranked = executor.evaluateExpression(call("sort_by_value_desc", var("scores")));
        failures += expect("sort_by_value_desc key order [bob,carol,alice]",
                ranked instanceof MapValue m
                        && new ArrayList<>(m.keySet()).equals(List.of("bob", "carol", "alice")));
        // non-mutating: original iteration order intact
        failures += expect("sort_by_value_desc is non-mutating",
                new ArrayList<>(((MapValue) ctx.getVariables().get("scores")).keySet())
                        .equals(List.of("alice", "bob", "carol")));

        Object rankedAsc = executor.evaluateExpression(call("sort_by_value", var("scores")));
        failures += expect("sort_by_value ascending [alice,carol,bob]",
                rankedAsc instanceof MapValue m
                        && new ArrayList<>(m.keySet()).equals(List.of("alice", "carol", "bob")));

        // sort_by_key: alphabetical key order
        ctx.getVariables().put("jumbled", mapVal(
                entry("cherry", 1), entry("apple", 2), entry("banana", 3)));
        Object byKey = executor.evaluateExpression(call("sort_by_key", var("jumbled")));
        failures += expect("sort_by_key [apple,banana,cherry]",
                byKey instanceof MapValue m
                        && new ArrayList<>(m.keySet()).equals(List.of("apple", "banana", "cherry")));

        // sort_map_by: custom arity-2 lambda over (key, value)
        Object custom = executor.evaluateExpression(
                call("sort_map_by_desc", var("scores"), keyLambda2("k", "v", var("v"))));
        failures += expect("sort_map_by_desc by value [bob,carol,alice]",
                custom instanceof MapValue m
                        && new ArrayList<>(m.keySet()).equals(List.of("bob", "carol", "alice")));

        // empty map -> empty map
        ctx.getVariables().put("emptyMap", new MapValue());
        Object emptySorted = executor.evaluateExpression(call("sort_by_value", var("emptyMap")));
        failures += expect("sort empty map -> empty map",
                emptySorted instanceof MapValue m && m.isEmpty());
        return failures;
    }

    private static int equalityChecks() {
        int failures = 0;
        // numeric coercion reaches inside collections
        failures += expect("[1] == [1.0]",
                Values.objectsEqual(List.of(1), List.of(1.0)));
        failures += expect("[1,2] != [2,1] (order-sensitive)",
                !Values.objectsEqual(List.of(1, 2), List.of(2, 1)));
        failures += expect("[1,2] == [1,2]",
                Values.objectsEqual(List.of(1, 2), List.of(1, 2)));
        failures += expect("different sizes not equal",
                !Values.objectsEqual(List.of(1, 2), List.of(1, 2, 3)));

        // maps: order-insensitive, numeric-aware values
        MapValue a = mapVal(entry("a", 1));
        MapValue b = mapVal(entry("a", 1.0));
        failures += expect("{a:1} == {a:1.0}", Values.objectsEqual(a, b));
        MapValue m1 = mapVal(entry("x", 1), entry("y", 2));
        MapValue m2 = mapVal(entry("y", 2), entry("x", 1));
        failures += expect("map equality is order-insensitive", Values.objectsEqual(m1, m2));
        MapValue m3 = mapVal(entry("x", 1), entry("y", 9));
        failures += expect("{x:1,y:2} != {x:1,y:9}", !Values.objectsEqual(m1, m3));

        // nested collections recurse
        MapValue nestedA = mapVal(entry("list", listVal(1, 2)),
                entry("inner", mapVal(entry("k", 3))));
        MapValue nestedB = mapVal(entry("list", listVal(1, 2.0)),
                entry("inner", mapVal(entry("k", 3.0))));
        failures += expect("nested list+map recurse numeric-aware",
                Values.objectsEqual(nestedA, nestedB));
        MapValue nestedC = mapVal(entry("list", listVal(2, 1)),
                entry("inner", mapVal(entry("k", 3))));
        failures += expect("nested list order still matters",
                !Values.objectsEqual(nestedA, nestedC));
        return failures;
    }

    private static int randomChecks() {
        int failures = 0;
        ASTExecutor executor = new ASTExecutor(null, new HashMap<>());
        ExecutionContext ctx = executor.context();

        // random_chance edges + probabilistic middle
        failures += expect("random_chance(0) is always false",
                Boolean.FALSE.equals(executor.evaluateExpression(call("random_chance", dnum(0)))));
        failures += expect("random_chance(1) is always true",
                Boolean.TRUE.equals(executor.evaluateExpression(call("random_chance", dnum(1)))));
        int hits = 0;
        for (int i = 0; i < 4000; i++) {
            if (Boolean.TRUE.equals(executor.evaluateExpression(
                    call("random_chance", dnum(0.3))))) {
                hits++;
            }
        }
        failures += expect("random_chance(0.3) lands roughly 30% (" + hits + "/4000)",
                hits > 800 && hits < 1600);

        // random_float in [lo, hi)
        boolean inRange = true;
        for (int i = 0; i < 2000; i++) {
            Object f = executor.evaluateExpression(call("random_float", dnum(2.0), dnum(5.0)));
            if (!(f instanceof Double d) || d < 2.0 || d >= 5.0) {
                inRange = false;
                break;
            }
        }
        failures += expect("random_float stays in [2.0, 5.0)", inRange);

        // random_bool: both outcomes appear over many draws
        boolean sawTrue = false;
        boolean sawFalse = false;
        for (int i = 0; i < 200 && !(sawTrue && sawFalse); i++) {
            if (Boolean.TRUE.equals(executor.evaluateExpression(call("random_bool")))) {
                sawTrue = true;
            } else {
                sawFalse = true;
            }
        }
        failures += expect("random_bool yields both true and false", sawTrue && sawFalse);

        // random_in: draws stay within the list; empty -> none
        ctx.getVariables().put("pool", listVal("a", "b", "c"));
        boolean allMembers = true;
        java.util.Set<Object> covered = new java.util.HashSet<>();
        for (int i = 0; i < 500; i++) {
            Object drawn = executor.evaluateExpression(call("random_in", var("pool")));
            if (!List.of("a", "b", "c").contains(drawn)) {
                allMembers = false;
                break;
            }
            covered.add(drawn);
        }
        failures += expect("random_in draws are all members", allMembers);
        failures += expect("random_in covers every element over many draws",
                covered.size() == 3);
        ctx.getVariables().put("emptyPool", listVal());
        failures += expect("random_in empty -> none",
                NoneValue.isNone(executor.evaluateExpression(call("random_in", var("emptyPool")))));

        // shuffle: non-mutating, same multiset, covers all 6 permutations of 3
        ctx.getVariables().put("deck", listVal(1, 2, 3));
        java.util.Set<String> perms = new java.util.HashSet<>();
        boolean sameMultiset = true;
        for (int i = 0; i < 3000; i++) {
            Object shuffled = executor.evaluateExpression(call("shuffle", var("deck")));
            if (!(shuffled instanceof List<?> l) || l.size() != 3
                    || !new java.util.HashSet<>(l).equals(new java.util.HashSet<>(List.of(1, 2, 3)))) {
                sameMultiset = false;
                break;
            }
            perms.add(l.toString());
        }
        failures += expect("shuffle preserves the multiset", sameMultiset);
        failures += expect("shuffle covers all 6 permutations (" + perms.size() + ")",
                perms.size() == 6);
        failures += expect("shuffle is non-mutating (deck intact)",
                ctx.getVariables().get("deck").equals(listVal(1, 2, 3)));
        return failures;
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private static void writeProp(PropertyDef def, Object owner, Object scriptValue) {
        Object coerced = def.coercion() != null ? def.coercion().apply(scriptValue) : scriptValue;
        def.setter().accept(owner, coerced);
    }

    private static FunctionCallExpression call(String name, Expression... args) {
        return new FunctionCallExpression(name, List.of(args));
    }

    private static IndexExpression index(Expression target, Expression key) {
        return new IndexExpression(target, key);
    }

    private static IndexAssignStatement setIndex(Expression target, Expression key,
            Expression value) {
        return new IndexAssignStatement(target, key, value);
    }

    private static VariableReference var(String name) {
        return new VariableReference(name);
    }

    private static StringLiteral str(String value) {
        return new StringLiteral(value);
    }

    private static NumberLiteral num(int value) {
        return new NumberLiteral(value, true);
    }

    private static NoneLiteral none() {
        return new NoneLiteral();
    }

    private static NumberLiteral dnum(double value) {
        return new NumberLiteral(value, false);
    }

    /** A fresh mutable list value (script lists are ArrayList<Object>). */
    private static List<Object> listVal(Object... items) {
        return new ArrayList<>(java.util.Arrays.asList(items));
    }

    private static Object[] entry(Object key, Object value) {
        return new Object[] { key, value };
    }

    /** A MapValue built from {@link #entry} pairs, in insertion order. */
    private static MapValue mapVal(Object[]... entries) {
        MapValue map = new MapValue();
        for (Object[] e : entries) {
            map.put(e[0], e[1]);
        }
        return map;
    }

    /** A {name, kills} player row for the leaderboard sort cases. */
    private static MapValue player(String name, int kills) {
        MapValue map = new MapValue();
        map.put("name", name);
        map.put("kills", kills);
        return map;
    }

    /** Project the "name" field out of a sorted list of player maps. */
    private static List<String> names(Object playerList) {
        List<String> out = new ArrayList<>();
        if (playerList instanceof List<?> list) {
            for (Object element : list) {
                if (element instanceof MapValue map) {
                    out.add(String.valueOf(map.get("name")));
                }
            }
        }
        return out;
    }

    /** A 1-arg key lambda whose body {@code return <expr>}. */
    private static LambdaExpression keyLambda(String param, Expression body) {
        ExecuteBlock block = new ExecuteBlock();
        block.addStatement(new ReturnStatement(body));
        return new LambdaExpression(
                List.of(new SwoftFunction.Param(param, null)), block, false);
    }

    /** A 2-arg key lambda (key, value) whose body {@code return <expr>}. */
    private static LambdaExpression keyLambda2(String p1, String p2, Expression body) {
        ExecuteBlock block = new ExecuteBlock();
        block.addStatement(new ReturnStatement(body));
        return new LambdaExpression(
                List.of(new SwoftFunction.Param(p1, null),
                        new SwoftFunction.Param(p2, null)),
                block, false);
    }

    private static boolean eq(Object value, int expected) {
        return value instanceof Number n && n.intValue() == expected
                && !(value instanceof Double);
    }

    private static int expect(String label, boolean condition) {
        System.out.println((condition ? "[PASS] " : "[FAIL] ") + label);
        return condition ? 0 : 1;
    }

    /** Records outbound packets; nothing is asserted on them here. */
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
    }
}
