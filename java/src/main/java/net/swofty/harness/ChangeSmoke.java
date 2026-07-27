package net.swofty.harness;

import java.io.File;
import java.io.OutputStream;
import java.io.PrintStream;
import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.player.AsyncPlayerConfigurationEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.ConnectionManager;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.packet.server.play.SystemChatPacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.swofty.ASTExecutor;
import net.swofty.TextFormat;
import net.swofty.compiler.FunctionRegistry;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftFunction;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.model.StorageBackendModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.nativebridge.representation.Command;
import net.swofty.persist.PersistStore;
import net.swofty.persist.change.ChangeRegistry;
import net.swofty.persist.network.SessionOwnership;
import net.swofty.props.PropertyTables;

/**
 * Change-event + cascade-guard smoke (design 1.10.0 §4 / §5), run with
 * {@code --change-smoke}.
 *
 * <p>Two halves, because the design has two halves:
 * <ul>
 *   <li><b>Standalone</b> — the invariant that {@code on_change} works with no
 *       network at all: it fires locally, {@code caused_here} is always true, a
 *       {@code broadcast} inside the handler actually reaches the server's
 *       players, {@code set x to x} fires nothing, a per-player handler binds
 *       {@code player} to the row's own subject, a collection reacts per ENTRY
 *       with {@code old is missing} = insert / {@code new is missing} = remove, a
 *       bulk clear is capped, a restart is a RESTORE (fires nothing), and a
 *       same-value-different-key cascade is bounded by the depth cap — with the
 *       chain logged — instead of running forever.</li>
 *   <li><b>Two servers over one backend</b> — the part a single server cannot
 *       prove: a change fires on BOTH the writer and the receiver with
 *       {@code caused_here} true only on the writer, the writer's own broadcast
 *       reaches its own players (network-only firing would silence exactly the
 *       wrong server), the writer does not fire twice on its own echo (§5.4), a
 *       session ACQUIRE+LOAD on the new owner fires nothing (a restore is not a
 *       change), and — the one a per-server counter gets wrong — an A → B → A
 *       ping-pong ACCUMULATES depth over the wire and trips the cap.</li>
 * </ul>
 *
 * <p>The observation instrument is a pair of real, online Minestom players with
 * capturing connections. That is deliberate: the whole point of §4.1 firing on
 * the writer too is that a {@code broadcast} in the handler must reach the
 * writer's own players, and only a real player on the online list can witness
 * that. Persistent counters are the secondary instrument.
 */
public final class ChangeSmoke {

    private static final long STARTED = System.currentTimeMillis();

    private static int failures;
    private static int checks;

    private static InstanceContainer instance;
    private static Wire steveWire;
    private static Wire alexWire;
    private static UUID steveUuid;
    private static UUID alexUuid;

    /** Everything written to stderr, so the cascade rejection can be asserted. */
    private static final StringBuilder ERR = new StringBuilder();

    private ChangeSmoke() {
    }

    /** mode: standalone — declarations and code identical to the network half. */
    private static final String LOCAL_FIXTURE = """
            storage {
                backend: files "REPLACED_AT_RUNTIME"
                flush: every 10 seconds
            }

            persistent change_log: Integer = 0
            persistent here_log: Integer = 0
            persistent entry_log: Integer = 0
            persistent inserts: Integer = 0
            persistent updates: Integer = 0
            persistent removes: Integer = 0
            persistent coin_events: Integer = 0
            persistent coin_owner: String = ""
            persistent trail: String = ""
            persistent boom_before: Integer = 0
            persistent boom_after: Integer = 0
            persistent entry_seen: Integer = 0
            persistent after_write: Integer = 0

            persistent boss_active: Boolean = false {
                on_change {
                    broadcast "boss ${old} -> ${new} here=${caused_here}"
                    add 1 to change_log
                    if caused_here {
                        add 1 to here_log
                    }
                }
            }

            // per-player: the declaration's key binds as 'player'
            persistent coins for Player: Integer = 0 {
                on_change {
                    set coin_owner to player.name
                    send "coins ${old} -> ${new}" to player
                    add 1 to coin_events
                }
            }

            // a collection reacts per ENTRY, with Optional old/new
            persistent leaderboard: Map<String, Integer> = new_map() {
                on_entry_change {
                    add 1 to entry_log
                    if old is missing {
                        broadcast "entry ${key} insert new=${new otherwise 0}"
                        add 1 to inserts
                    } else if new is missing {
                        broadcast "entry ${key} remove old=${old otherwise 0}"
                        add 1 to removes
                    } else {
                        broadcast "entry ${key} update ${old otherwise 0} to ${new otherwise 0}"
                        add 1 to updates
                    }
                }
            }

            // §5.2's allowed exception: the SAME value at a DIFFERENT key. It is
            // legitimate and unprovable statically, so layer 3 (the depth cap)
            // is what bounds it at runtime.
            persistent scores for String: Integer = 0 {
                on_change {
                    set scores for "chain" to (scores for "chain") + 1
                }
            }

            // ORDER: two rapid writes to the same value must fire in order with
            // the old/new pairs chained, no intermediate lost or transposed
            persistent order_val: Integer = 0 {
                on_change {
                    set trail to "${trail}[${old}->${new}]"
                }
            }

            // ISOLATION: a handler that throws mid-body must not abort the
            // dispatch, the write, or the writer
            persistent thrower: Integer = 0 {
                on_change {
                    add 1 to boom_before
                    play sound "bad name ${boom_before}!!" to all players
                    add 1 to boom_after
                }
            }

            // ISOLATION inside one BATCH: the throwing entry must not eat the
            // entries after it
            persistent boom_map: Map<String, Integer> = new_map() {
                on_entry_change {
                    add 1 to entry_seen
                    if key is "bad" {
                        play sound "bad name ${key}!!" to all players
                    }
                }
            }

            command "flip" { execute { set boss_active to true } }
            command "same" { execute { set boss_active to true } }
            command "insert" { execute { set leaderboard at "a" to 1 } }
            command "update" { execute { set leaderboard at "a" to 2 } }
            command "resave" { execute { set leaderboard at "a" to 2 } }
            command "drop" { execute { delete leaderboard at "a" } }
            command "fill" {
                execute {
                    set n to 0
                    loop 100 times {
                        set n to n + 1
                        set leaderboard at "p${n}" to n
                    }
                }
            }
            command "clear" { execute { set leaderboard to new_map() } }
            command "cascade" { execute { set scores for "seed" to 1 } }
            command "reinsert" { execute { set leaderboard at "p99" to 9 } }
            command "rapid" {
                execute {
                    set order_val to 1
                    set order_val to 2
                    set order_val to 3
                }
            }
            command "boom" {
                execute {
                    set thrower to 1
                    add 1 to after_write
                }
            }
            command "boombatch" {
                execute {
                    set m to new_map()
                    set m at "a" to 1
                    set m at "bad" to 1
                    set m at "c" to 1
                    set boom_map to m
                }
            }
            """;

    /** mode: network — same surface, two servers. */
    private static final String NET_FIXTURE = """
            storage {
                backend: mysql { host: "10.0.0.5", port: 3306, database: "net", user: "mc", password: "hunter2" }
                mode: network
                flush: every 30 seconds
            }

            persistent fired_here: Integer = 0
            persistent fired_remote: Integer = 0

            persistent pot: Integer = 0 {
                on_change {
                    broadcast "pot=${new} here=${caused_here}"
                    if caused_here {
                        add 1 to fired_here
                    } else {
                        add 1 to fired_remote
                    }
                }
            }

            // session-owned: it lives on exactly ONE server, so it never
            // broadcasts - and a join LOADING it is a restore, not a change.
            persistent coins for Player: Integer = 0 {
                on_change {
                    send "coins=${new} here=${caused_here}" to player
                }
            }

            // the A -> B -> A ping-pong, written through §5.2's allowed
            // exception (the same value at a DIFFERENT key — a direct self-write
            // is a compile error). Every server that sees somebody ELSE's change
            // writes again, so nothing but a PROPAGATING depth can stop it: a
            // per-server counter would see a "fresh" depth-0 change on every hop
            // and cascade forever.
            persistent ping for String: Integer = 0 {
                on_change {
                    if not caused_here {
                        add 1 to ping for "echo"
                    }
                }
            }

            command "bet" { execute { add 50 to pot } }
            command "hold" { execute { set pot to 50 } }
            command "serve" { execute { add 1 to ping for "seed" } }
            """;

    public static int run() throws Exception {
        PrintStream realErr = System.err;
        System.setErr(new PrintStream(new TeeStream(realErr, ERR), true));
        try {
            boot();
            standalone();
            network();
        } finally {
            System.setErr(realErr);
        }
        System.out.println("[CHANGE] " + (checks - failures) + "/" + checks + " assertion(s) passed");
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // a real (headless) server with two real, online players
    // ------------------------------------------------------------------

    /**
     * {@code broadcast} sends to {@code getOnlinePlayers()}, so proving §4.1's
     * "the writer's own players hear it" needs players that are genuinely on
     * that list. Building them by hand and walking them through
     * config → play is how the other Minestom-backed harnesses do it; the spawn
     * half of {@code UNSAFE_init} needs a real login handshake and throws here,
     * which is irrelevant — the player is registered as online either way, and
     * that is the only thing a broadcast consults.
     */
    private static void boot() {
        MinecraftServer.init();
        MinecraftServer.getExceptionManager().setExceptionHandler(t -> {
        });
        PropertyTables.ensureRegistered();
        instance = MinecraftServer.getInstanceManager().createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.STONE));
        instance.loadChunk(0, 0).join();

        steveWire = new Wire();
        alexWire = new Wire();
        Player steve = online("Steve", steveWire);
        Player alex = online("Alex", alexWire);
        steveUuid = steve.getUuid();
        alexUuid = alex.getUuid();

        require("two players are ONLINE, so a broadcast has somebody to reach",
                MinecraftServer.getConnectionManager().getOnlinePlayers().size() == 2);
        require("a player is resolvable by uuid (the row key a per-player handler binds)",
                MinecraftServer.getConnectionManager().getOnlinePlayerByUuid(steveUuid) == steve);
    }

    /**
     * Config → play without the configuration handshake:
     * {@code doConfiguration} blocks until the client acknowledges, which a fake
     * connection never does. {@code setPendingOptions} supplies the one thing
     * that phase would have produced (the spawn instance), so the transition
     * queue can drain and the player lands on the online list.
     */
    private static Player online(String name, Wire wire) {
        Player player = new Player(wire, new GameProfile(UUID.randomUUID(), name));
        player.setPendingOptions(instance, false);
        ConnectionManager connections = MinecraftServer.getConnectionManager();
        connections.transitionConfigToPlay(player);
        connections.updateWaitingPlayers();
        return player;
    }

    // ------------------------------------------------------------------
    // §4.1 in mode: standalone
    // ------------------------------------------------------------------

    private static void standalone() throws Exception {
        Path dir = Files.createTempDirectory("swoft-change-smoke");
        Path data = dir.resolve("data");
        Path script = dir.resolve("change_smoke.sw");
        Files.writeString(script, LOCAL_FIXTURE.replace("REPLACED_AT_RUNTIME",
                data.toString().replace("\\", "/")));

        ParsedScript parsed = load(script);
        StorageConfigModel config = new StorageConfigModel(
                StorageBackendModel.files(data.toString()),
                parsed.storage() != null ? parsed.storage().flushTicks()
                        : StorageConfigModel.DEFAULT_FLUSH_TICKS);

        System.out.println("[CHANGE] --- (§4.1) mode: standalone ---");
        PersistStore store = PersistStore.initialize(parsed.persistents(), config);
        ChangeRegistry.install(parsed.persistents());
        try {
            require("a program with handlers arms the registry", ChangeRegistry.armed());

            // ---- a real change fires, once, with caused_here = true ----
            int mark = steveWire.chat.size();
            run(parsed, "flip", store);
            require("a real change fires the handler exactly once",
                    eq(store.get("change_log", ""), 1));
            require("caused_here is TRUE in standalone (the writer is always this server)",
                    eq(store.get("here_log", ""), 1));

            // ---- (b) the handler's broadcast reached this server's players ----
            List<String> flipped = since(steveWire, mark);
            require("a broadcast INSIDE the handler reaches this server's own players",
                    count(flipped, "boss false -> true here=true") == 1);
            require("...and every online player, not just one",
                    count(alexWire.chat, "boss false -> true here=true") == 1);

            // ---- (c) 'set x to x' fires nothing ----
            mark = steveWire.chat.size();
            run(parsed, "same", store);
            require("'set x to x' fires NOTHING (no-op suppression, §4.1/§5.1)",
                    eq(store.get("change_log", ""), 1) && since(steveWire, mark).isEmpty());

            // ---- (e) a per-player handler binds 'player' to the ROW's subject ----
            int steveMark = steveWire.chat.size();
            int alexMark = alexWire.chat.size();
            store.set("coins", steveUuid.toString(), 10);
            require("a per-player on_change binds 'player' to the row's own subject",
                    eq(store.get("coin_owner", ""), "Steve"));
            require("...and 'send ... to player' reaches exactly that player",
                    count(since(steveWire, steveMark), "coins 0 -> 10") == 1
                            && since(alexWire, alexMark).isEmpty());

            steveMark = steveWire.chat.size();
            alexMark = alexWire.chat.size();
            store.set("coins", alexUuid.toString(), 3);
            require("the binding follows the ROW, not the previous firing",
                    eq(store.get("coin_owner", ""), "Alex")
                            && count(since(alexWire, alexMark), "coins 0 -> 3") == 1
                            && since(steveWire, steveMark).isEmpty());
            require("two per-player rows fired two events, not one",
                    eq(store.get("coin_events", ""), 2));

            // ---- (f) per-ENTRY: insert / update / remove ----
            mark = steveWire.chat.size();
            run(parsed, "insert", store);
            require("an INSERT fires with old = none",
                    eq(store.get("inserts", ""), 1) && eq(store.get("entry_log", ""), 1)
                            && count(since(steveWire, mark), "entry a insert new=1") == 1);

            mark = steveWire.chat.size();
            run(parsed, "update", store);
            require("an UPDATE fires with BOTH old and new present",
                    eq(store.get("updates", ""), 1) && eq(store.get("entry_log", ""), 2)
                            && count(since(steveWire, mark), "entry a update 1 to 2") == 1);

            mark = steveWire.chat.size();
            run(parsed, "resave", store);
            require("re-storing an entry with the SAME value fires nothing",
                    eq(store.get("entry_log", ""), 2) && since(steveWire, mark).isEmpty());

            mark = steveWire.chat.size();
            run(parsed, "drop", store);
            require("a REMOVE fires with new = none",
                    eq(store.get("removes", ""), 1) && eq(store.get("entry_log", ""), 3)
                            && count(since(steveWire, mark), "entry a remove old=2") == 1);

            // ---- (g) a bulk clear is batched and capped ----
            mark = steveWire.chat.size();
            run(parsed, "fill", store);
            require("a collection reacts per ENTRY (100 inserts = 100 events)",
                    eq(store.get("entry_log", ""), 103)
                            && count(since(steveWire, mark), " insert new=") == 100);

            mark = steveWire.chat.size();
            run(parsed, "clear", store);
            require("a bulk clear of a large map is BATCHED AND CAPPED, not a storm",
                    eq(store.get("entry_log", ""), 167)
                            && count(since(steveWire, mark), " remove old=") == 64);
            require("...and the suppressed remainder is summarised, not silently dropped",
                    eq(store.get("removes", ""), 65));
            // the cap bounds the EVENTS, never the state: the map really is
            // empty, and the shadow of a SUPPRESSED entry was updated too - so
            // re-adding one of them is an INSERT, not a phantom update against a
            // value the handler was never told had gone
            require("a capped bulk clear still leaves the final state correct (map empty)",
                    store.get("leaderboard", "") instanceof java.util.Map<?, ?> map
                            && map.isEmpty());
            mark = steveWire.chat.size();
            int insertsBefore = asInt(store.get("inserts", ""));
            run(parsed, "reinsert", store);
            require("...and a SUPPRESSED entry's shadow was cleared too (re-add = INSERT)",
                    eq(store.get("inserts", ""), insertsBefore + 1)
                            && count(since(steveWire, mark), "entry p99 insert new=9") == 1);

            // ---- ORDER: two rapid writes, in order, correctly paired ----
            run(parsed, "rapid", store);
            require("rapid writes fire IN ORDER with chained old/new (nothing lost or transposed)",
                    eq(store.get("trail", ""), "[0->1][1->2][2->3]"));

            // ---- ISOLATION: a throwing handler is logged and stepped over ----
            int errMark2 = ERR.length();
            run(parsed, "boom", store);
            require("a handler that THROWS does not abort the write itself",
                    eq(store.get("thrower", ""), 1));
            require("...nor the writer (the statement after the write still ran)",
                    eq(store.get("after_write", ""), 1));
            require("...and it is LOGGED, not swallowed",
                    errSince(errMark2).contains("the on_change handler of 'thrower' failed"));
            require("...with the body stopping at the throw, not half-re-running",
                    eq(store.get("boom_before", ""), 1) && eq(store.get("boom_after", ""), 0));

            errMark2 = ERR.length();
            run(parsed, "boombatch", store);
            require("one throwing ENTRY does not eat the rest of the batch",
                    eq(store.get("entry_seen", ""), 3)
                            && errSince(errMark2).contains(
                                    "the on_entry_change handler of 'boom_map' failed"));
            require("...and the whole value landed regardless",
                    store.get("boom_map", "") instanceof java.util.Map<?, ?> boom
                            && boom.size() == 3);

            // ---- §5.3 the depth cap, with the chain logged ----
            int errMark = ERR.length();
            run(parsed, "cascade", store);
            require("a same-value-different-key cascade stops at the depth cap (8 writes)",
                    eq(store.get("scores", "chain"), 8));
            String rejection = errSince(errMark);
            require("the rejection is LOGGED with the chain path, never silently dropped",
                    rejection.contains("change cascade exceeded depth 8")
                            && rejection.contains("chain: scores(seed) -> scores(chain)"));

            // ---- a restart is a RESTORE, not a change ----
            int changeLog = asInt(store.get("change_log", ""));
            int entryLog = asInt(store.get("entry_log", ""));
            int coinEvents = asInt(store.get("coin_events", ""));
            steveMark = steveWire.chat.size();
            PersistStore.shutdownActive();

            PersistStore reloaded = PersistStore.initialize(parsed.persistents(), config);
            ChangeRegistry.install(parsed.persistents());
            require("a restart LOADS without firing anything (a restore is not a change)",
                    eq(reloaded.get("change_log", ""), changeLog)
                            && eq(reloaded.get("entry_log", ""), entryLog)
                            && eq(reloaded.get("coin_events", ""), coinEvents)
                            && since(steveWire, steveMark).isEmpty());
            require("the reloaded values are the flushed ones, not the defaults",
                    eq(reloaded.get("boss_active", ""), Boolean.TRUE));

            // and a no-op write against a BOOT-LOADED value still fires nothing:
            // the shadow has to be seeded from the load, not from the default
            steveMark = steveWire.chat.size();
            run(parsed, "same", reloaded);
            require("a no-op write against a boot-loaded value fires nothing either",
                    eq(reloaded.get("change_log", ""), changeLog)
                            && since(steveWire, steveMark).isEmpty());

            // ---- a HOT RELOAD (the store SURVIVES, the handlers do not) ----
            // The teardown must disarm immediately, and the generation must move
            // so that a dispatch parked on the next tick before the reload is
            // dropped instead of running the old body against the new program.
            long before = ChangeRegistry.generation();
            ChangeRegistry.reset();
            require("the reload teardown disarms the handlers at once",
                    !ChangeRegistry.armed() && ChangeRegistry.generation() != before);
            steveMark = steveWire.chat.size();
            reloaded.set("boss_active", "", false);
            require("a torn-down handler cannot fire (no ghost between teardown and load)",
                    since(steveWire, steveMark).isEmpty());

            long torn = ChangeRegistry.generation();
            ChangeRegistry.install(parsed.persistents());
            require("re-installing moves the generation again (queued batches are stale)",
                    ChangeRegistry.generation() != torn && ChangeRegistry.armed());
            steveMark = steveWire.chat.size();
            reloaded.set("boss_active", "", false);
            require("the reload itself fires nothing (the shadows were RE-SEEDED, not reset)",
                    since(steveWire, steveMark).isEmpty());
            steveMark = steveWire.chat.size();
            reloaded.set("boss_active", "", true);
            require("...and the freshly-installed handler reacts to the next real change",
                    count(since(steveWire, steveMark), "boss false -> true here=true") == 1);
        } finally {
            PersistStore.shutdownActive();
            ChangeRegistry.reset();
        }
    }

    // ------------------------------------------------------------------
    // §4.1 "fires on EVERY server" + §5.3/§5.4 across the wire
    // ------------------------------------------------------------------

    private static void network() throws Exception {
        Path dir = Files.createTempDirectory("swoft-change-net");
        Path script = dir.resolve("change_net.sw");
        Files.writeString(script, NET_FIXTURE);

        ParsedScript parsed = load(script);
        StorageConfigModel declared = parsed.storage();
        require("the network fixture compiled to mode: network",
                declared != null && declared.isNetwork());
        StorageConfigModel config = new StorageConfigModel(declared.backend(),
                declared.flushTicks(), declared.mode(), declared.handoffFailure(), null);

        System.out.println("[CHANGE] --- (§4.1/§5.3/§5.4) two servers, one backend ---");
        NetSmoke.SharedBackend shared = new NetSmoke.SharedBackend();
        PersistStore a = PersistStore.createIsolated(parsed.persistents(), config, shared, "chg-A");
        PersistStore b = PersistStore.createIsolated(parsed.persistents(), config, shared, "chg-B");
        ChangeRegistry.install(parsed.persistents());
        try {
            // ---- (a)+(b) one write on A, both servers react, one of them "here"
            int mark = steveWire.chat.size();
            run(parsed, "bet", a);
            require("the WRITER fires its own handler (caused_here = true)",
                    await(() -> eq(a.get("fired_here", ""), 1)));
            require("the other server fires it too, with caused_here = false",
                    await(() -> eq(a.get("fired_remote", ""), 1)));
            require("the writer's OWN players hear the handler's broadcast (§4.1)",
                    await(() -> count(since(steveWire, mark), "pot=50 here=true") == 1));
            require("the other server's players hear it as a remote change",
                    await(() -> count(since(steveWire, mark), "pot=50 here=false") == 1));
            require("caused_here is true on EXACTLY ONE server (§5.4: no self-echo)",
                    stable(() -> count(since(steveWire, mark), "pot=50 here=true") == 1
                            && count(since(steveWire, mark), "pot=50 here=false") == 1
                            && eq(a.get("fired_here", ""), 1)
                            && eq(a.get("fired_remote", ""), 1)));

            // ---- (d) a joining player's session load fires NOTHING ----
            String key = steveUuid.toString();
            require("A acquires Steve's session", SessionOwnership.acquireSession(a, a.network(),
                    key) == null);
            int steveMark = steveWire.chat.size();
            PersistStore previous = PersistStore.swapActive(a);
            try {
                a.set("coins", key, 25);
            } finally {
                PersistStore.swapActive(previous);
            }
            require("a session-owned write fires on its owner only (no broadcast to echo)",
                    count(since(steveWire, steveMark), "coins=25 here=true") == 1
                            && count(since(steveWire, steveMark), "here=false") == 0);
            SessionOwnership.releaseSession(a, a.network(), key);

            steveMark = steveWire.chat.size();
            require("B acquires the released session", SessionOwnership.acquireSession(b,
                    b.network(), key) == null);
            require("B LOADED the value", eq(b.get("coins", key), 25));
            require("a joining player's session load fires NOTHING (restore != change)",
                    since(steveWire, steveMark).isEmpty());

            // the same thing through the REAL join hook, not just the entry point
            steveMark = steveWire.chat.size();
            SessionOwnership.releaseSession(b, b.network(), key);
            EventDispatcher.call(new AsyncPlayerConfigurationEvent(
                    MinecraftServer.getConnectionManager().getOnlinePlayerByUuid(steveUuid), true));
            require("...through the real join hook too, and the value is present",
                    since(steveWire, steveMark).isEmpty() && eq(a.get("coins", key), 25));

            // ---- (§5.3) the A -> B -> A cascade trips the cap ----
            int errMark = ERR.length();
            run(parsed, "serve", a);
            require("the cross-server cascade reaches the cap",
                    await(() -> eq(a.get("ping", "echo"), 8)));
            require("the A -> B -> A ping-pong TERMINATES there (the token travels, §5.3)",
                    stable(() -> eq(a.get("ping", "echo"), 8)));
            require("both servers converge on the same value",
                    await(() -> eq(b.get("ping", "echo"), a.get("ping", "echo"))));
            String rejection = lastRejection(errSince(errMark));
            require("the cap tripped on a chain that ACCUMULATED across the wire",
                    rejection != null && arrows(rejection) >= 8);
            require("...on the chain server A started, proving the token rode the broadcast",
                    rejection != null && rejection.contains("started on 'chg-A'"));

            // ---- a THIRD server booting onto an already-written value ----
            // In the real startup order the STORE is built first and the
            // compiled program arms the handlers afterwards, so the boot load
            // happens with nothing armed. The shadow still has to come from that
            // load: otherwise the first write diffs a live value against the
            // declared DEFAULT and fires a phantom change (§4.1 "not on
            // load/restore"). Last, because shutting it down detaches the
            // JVM-wide session hooks.
            ChangeRegistry.reset();
            PersistStore c = PersistStore.createIsolated(parsed.persistents(), config, shared,
                    "chg-C");
            ChangeRegistry.install(parsed.persistents());
            try {
                require("a fresh server boot-loaded the replicated value", eq(c.get("pot", ""), 50));
                int freshMark = steveWire.chat.size();
                run(parsed, "hold", c);
                require("'set pot to 50' on a BOOT-LOADED 50 fires nothing (restore != change)",
                        stable(() -> since(steveWire, freshMark).isEmpty()));
            } finally {
                c.shutdown();
            }
        } finally {
            PersistStore.swapActive(null);
            ChangeRegistry.reset();
            a.shutdown();
            b.shutdown();
            SessionOwnership.uninstall();
        }
    }

    // ------------------------------------------------------------------
    // plumbing
    // ------------------------------------------------------------------

    private static ParsedScript load(Path script) throws Exception {
        ParsedScript parsed =
                SwoftJsonLoader.load(SwoftcCompiler.compile(new File(script.toString())));
        FunctionRegistry.clear();
        for (SwoftFunction function : parsed.functions()) {
            FunctionRegistry.register(function);
        }
        return parsed;
    }

    private static void run(ParsedScript parsed, String name, PersistStore on) {
        Command command = parsed.commands().stream()
                .filter(c -> c != null && name.equals(c.getName()))
                .findFirst().orElse(null);
        if (command == null || command.getExecuteBlock() == null) {
            require("the fixture declares a '" + name + "' command", false);
            return;
        }
        PersistStore previous = PersistStore.swapActive(on);
        try {
            new ASTExecutor(new ExecHarness.CapturingSender(), new HashMap<>())
                    .execute(command.getExecuteBlock());
        } catch (Exception e) {
            require("running '" + name + "' raised " + e, false);
        } finally {
            PersistStore.swapActive(previous);
        }
    }

    /** Poll until the condition holds (the bus is polled, so a hop takes a moment). */
    private static boolean await(java.util.function.BooleanSupplier condition) {
        long deadline = System.currentTimeMillis() + 8_000L;
        while (System.currentTimeMillis() < deadline) {
            if (condition.getAsBoolean()) {
                return true;
            }
            sleep(50);
        }
        return condition.getAsBoolean();
    }

    /** Hold for a while: proves a cascade STOPPED rather than merely paused. */
    private static boolean stable(java.util.function.BooleanSupplier condition) {
        for (int i = 0; i < 40; i++) {
            if (!condition.getAsBoolean()) {
                return false;
            }
            sleep(50);
        }
        return true;
    }

    private static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    /** The chat lines a player received after {@code mark}. */
    private static List<String> since(Wire wire, int mark) {
        List<String> all = List.copyOf(wire.chat);
        return mark >= all.size() ? List.of() : all.subList(mark, all.size());
    }

    private static long count(List<String> lines, String needle) {
        return lines.stream().filter(line -> line.contains(needle)).count();
    }

    private static String errSince(int mark) {
        synchronized (ERR) {
            return mark >= ERR.length() ? "" : ERR.substring(mark);
        }
    }

    /** The last cascade-rejection line in {@code log}, or null. */
    private static String lastRejection(String log) {
        String found = null;
        for (String line : log.split("\\R")) {
            if (line.contains("change cascade exceeded depth")) {
                found = line;
            }
        }
        return found;
    }

    /** How many hops the logged chain path holds. */
    private static int arrows(String line) {
        int at = line.indexOf("chain: ");
        if (at < 0) {
            return 0;
        }
        int count = 0;
        int from = at;
        while ((from = line.indexOf(" -> ", from)) >= 0) {
            count++;
            from += 4;
        }
        return count;
    }

    private static int asInt(Object value) {
        return value instanceof Number number ? number.intValue() : -1;
    }

    private static boolean eq(Object actual, Object expected) {
        if (actual instanceof Number left && expected instanceof Number right) {
            return left.doubleValue() == right.doubleValue();
        }
        return actual != null && actual.equals(expected);
    }

    private static void require(String what, boolean ok) {
        checks++;
        if (!ok) {
            failures++;
        }
        System.out.println("[CHANGE] " + (ok ? "PASS" : "FAIL") + " ("
                + (System.currentTimeMillis() - STARTED) + "ms)  " + what);
    }

    /** A player connection that records the chat it is sent. */
    private static final class Wire extends PlayerConnection {
        private final List<String> chat = new CopyOnWriteArrayList<>();

        @Override
        public void sendPacket(SendablePacket packet) {
            if (packet instanceof SystemChatPacket message) {
                chat.add(TextFormat.plain(message.message()));
            }
        }

        @Override
        public SocketAddress getRemoteAddress() {
            return new InetSocketAddress(0);
        }

        @Override
        public boolean isOnline() {
            return true;
        }
    }

    /** Keeps stderr visible while recording it for the cascade assertions. */
    private static final class TeeStream extends OutputStream {
        private final PrintStream echo;
        private final StringBuilder sink;

        private TeeStream(PrintStream echo, StringBuilder sink) {
            this.echo = echo;
            this.sink = sink;
        }

        @Override
        public void write(int b) {
            echo.write(b);
            synchronized (sink) {
                sink.append((char) (b & 0xFF));
            }
        }

        @Override
        public void write(byte[] bytes, int off, int len) {
            echo.write(bytes, off, len);
            synchronized (sink) {
                sink.append(new String(bytes, off, len));
            }
        }

        @Override
        public void flush() {
            echo.flush();
        }
    }

}
