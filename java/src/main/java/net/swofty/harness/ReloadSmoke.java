package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

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
import net.swofty.InstanceRegistry;
import net.swofty.SwoftLangEngine;
import net.swofty.entities.ScriptEntityRegistry;
import net.swofty.mobs.MobRegistry;
import net.swofty.persist.PersistStore;
import net.swofty.props.PropertyTables;
import net.swofty.sched.ScheduleRegistry;
import net.swofty.structs.InstanceReceiverRuntime;
import net.swofty.ui.SwoftSidebarRuntime;

/**
 * --reload-smoke (#58): the ROBUST HOT-RELOAD TEARDOWN invariant, end to end.
 *
 * <p>Boots a real {@code MinecraftServer.init()}, points a {@link SwoftLangEngine}
 * at a temp scripts dir holding one script that exercises every "grows on reload"
 * subsystem at once — a repeating {@code every 1 tick} schedule, a global
 * {@code Player on_join} handler, a scoreboard HUD, a script-spawned mob, and a
 * PERSISTENT REACTIVE struct ({@code Duel} with an {@code @EventReceiver a: Player}
 * reacting {@code on_join}) rooted in a persistent map — then drives a player join,
 * reloads the engine THREE times through the central {@link net.swofty.reload.ReloadRegistry}
 * teardown, and asserts the single-live-set invariant:
 *
 * <ul>
 *   <li>schedulers do not accumulate (exactly one live {@code every} across reloads);</li>
 *   <li>the {@code on_join} handler fires exactly once per join (no ghost handlers);</li>
 *   <li>script-spawned mobs are torn down on reload (no orphans) and re-spawn as one;</li>
 *   <li>the scoreboard HUD refresh task is not duplicated;</li>
 *   <li>the reactive-instance index is REBUILT from the surviving persistent root
 *       (count stays 1, never doubled);</li>
 *   <li>PERSISTENT data set before the reloads survives them;</li>
 *   <li>the reactive instance re-registers post-reload and fires again.</li>
 * </ul>
 */
public final class ReloadSmoke {

    private static int failures = 0;

    private ReloadSmoke() {
    }

    private static void check(String label, boolean ok, Object detail) {
        if (ok) {
            System.out.println("  ok   " + label);
        } else {
            failures++;
            System.out.println("  FAIL " + label + "  -> " + detail);
        }
    }

    // The player creates its Duel only once (guarded), so a later join exercises
    // the SURVIVING instance's reactive handler rather than overwriting it. The
    // global on_join increments a plain persistent (single-fire proof) and spawns
    // one mob + shows the scoreboard (teardown/HUD proofs).
    private static final String SCRIPT = """
            storage {
                backend: files "__STORAGE__"
            }

            struct Duel {
                @EventReceiver a: Player
                hits: Map<String, Integer>

                a {
                    on_join {
                        // in-place mutation of a reference field propagates to the
                        // instance (durable via markDirty) — a scalar rebind would not
                        set hits at "n" to (hits["n"] otherwise 0) + 1
                    }
                }
            }

            persistent duels: Map<String, Duel> = new_map()
            persistent joins: Integer = 0

            mob Grunt {
                type: "ZOMBIE"
                health: 20
            }

            scoreboard "main" {
                title: "Reload"
                update: every 20 ticks
                lines {
                    line "hi"
                }
            }

            every 1 tick {
                set ticknop to 1
            }

            Player {
                on_join {
                    set joins to joins + 1
                    spawn mob Grunt at location(0, 42, 0) as m
                    show scoreboard "main" to player
                    if not (duels has "arena") {
                        set duels at "arena" to Duel { a: player, hits: new_map() }
                    }
                }
            }
            """;

    public static int run() throws Exception {
        MinecraftServer.init();
        PropertyTables.ensureRegistered();

        Path dir = Files.createTempDirectory("swoft-reload-smoke");
        Path storage = Files.createTempDirectory("swoft-reload-store");
        Path script = dir.resolve("reload.sw");
        Files.writeString(script,
                SCRIPT.replace("__STORAGE__", storage.toString().replace("\\", "/")));

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 40, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        // Spawn the player BEFORE the engine registers its listeners: setInstance
        // fires an implicit PlayerSpawnEvent, and attaching the on_join listener
        // first would let that implicit spawn double-count against the controlled
        // dispatches below. With no listeners yet, the implicit spawn is a no-op.
        Player p = new Player(new FakeConnection(),
                new GameProfile(UUID.randomUUID(), "Reloader"));
        p.setInstance(instance, new Pos(0, 42, 0)).join();

        // engine on the temp dir: initialize() parses + wires persistence, the
        // first register() arms every subsystem's teardown callback.
        SwoftLangEngine engine = new SwoftLangEngine(dir.toString(), "sw");
        engine.initialize();
        engine.register();

        int schedBase = ScheduleRegistry.liveCount();
        int hudBase = SwoftSidebarRuntime.taskCount();
        check("baseline: one live every-schedule", schedBase == 1, schedBase);
        check("baseline: one scoreboard HUD task", hudBase == 1, hudBase);

        // ---- first join: global handler fires + Duel created into persistent ----
        long joins0 = joins();
        EventDispatcher.call(new PlayerSpawnEvent(p, instance, true));

        check("first join: joins persistent +1", joins() == joins0 + 1, joins());
        check("first join: one script-spawned mob", MobRegistry.all(null).size() == 1,
                MobRegistry.all(null).size());
        int bind1 = InstanceReceiverRuntime.bindingCount();
        check("first join: reactive Duel registered (1 binding)", bind1 == 1, bind1);
        long joinsAfterFirst = joins();
        int duelScoreAfterFirst = duelScore();
        // the global on_join created the Duel this same event; the reactive
        // listener (registered after the global one) sees the freshly-rebuilt
        // index and fires too, so score is already 1.
        check("first join: reactive handler fired once (score 1)",
                duelScoreAfterFirst == 1, duelScoreAfterFirst);

        // ---- reload 3x through the central ReloadRegistry teardown ----
        for (int i = 1; i <= 3; i++) {
            engine.reload();
        }

        // INVARIANT: exactly one live set, no accumulation, no ghosts.
        int schedAfter = ScheduleRegistry.liveCount();
        check("after 3 reloads: schedulers NOT accumulated (still 1)",
                schedAfter == schedBase, schedAfter);
        int hudAfter = SwoftSidebarRuntime.taskCount();
        check("after 3 reloads: HUD task NOT duplicated (still 1)",
                hudAfter == hudBase, hudAfter);
        int mobsAfter = MobRegistry.all(null).size();
        check("after 3 reloads: script mobs torn down (0, no orphans)",
                mobsAfter == 0, mobsAfter);
        int entAfter = ScriptEntityRegistry.count();
        check("after 3 reloads: script entities torn down (0)", entAfter == 0, entAfter);
        int bindAfter = InstanceReceiverRuntime.bindingCount();
        check("after 3 reloads: reactive index REBUILT from persistent (still 1, not doubled)",
                bindAfter == 1, bindAfter);

        // PERSISTENT data set before the reloads survives them.
        check("after 3 reloads: persistent 'joins' survived",
                joins() == joinsAfterFirst, joins());
        check("after 3 reloads: persistent Duel survived (score kept)",
                duelScore() == duelScoreAfterFirst, duelScore());

        // ---- second join AFTER reloads: single fire + reactive re-fires ----
        long joinsMid = joins();
        int scoreMid = duelScore();
        EventDispatcher.call(new PlayerSpawnEvent(p, instance, false));

        check("post-reload join: on_join fired exactly once (no ghosts)",
                joins() == joinsMid + 1, joins());
        check("post-reload join: still one script-spawned mob (no dupes)",
                MobRegistry.all(null).size() == 1, MobRegistry.all(null).size());
        check("post-reload join: reactive instance re-registered + fired (score +1)",
                duelScore() == scoreMid + 1, duelScore());
        check("post-reload join: reactive index still 1 (guard kept single Duel)",
                InstanceReceiverRuntime.bindingCount() == 1,
                InstanceReceiverRuntime.bindingCount());

        // ---- --watch path: a .sw change on disk reloads via the SAME teardown ----
        // The standalone --watch flag's ReloadWatcher recompiles the changed file
        // then calls exactly this engine.reload(). Simulate a file edit that adds a
        // SECOND every-schedule, then reload: the new program must fully replace the
        // old (two live schedules, not 1+2=3 accumulated) with persistence intact.
        long joinsBeforeWatch = joins();
        String edited = SCRIPT.replace("__STORAGE__", storage.toString().replace("\\", "/"))
                + "\nevery 2 ticks {\n    set ticknop2 to 1\n}\n";
        Files.writeString(script, edited);
        engine.reload();
        int schedWatch = ScheduleRegistry.liveCount();
        check("--watch reload: new program applied (2 schedules, no accumulation)",
                schedWatch == 2, schedWatch);
        check("--watch reload: persistent 'joins' survived the file-change reload",
                joins() == joinsBeforeWatch, joins());
        check("--watch reload: reactive index still rebuilt to 1 from surviving root",
                InstanceReceiverRuntime.bindingCount() == 1,
                InstanceReceiverRuntime.bindingCount());

        // ---- full DISK round-trip of the struct-rooted persistent map ----
        // The reloads above kept the in-memory cache, so prove the reactive Duel
        // (a Map<String, Duel>, newly persistable) also survives a real backend
        // flush + reload-from-disk: shut the store (final flush), reopen it from
        // the same files backend, and require the reactive hits count back.
        int hitsBeforeFlush = duelScore();
        long joinsBeforeFlush = joins();
        net.swofty.compiler.ParsedScript ps =
                engine.getScriptLoader().parseScript(script.toFile());
        PersistStore.shutdownActive();
        PersistStore.initialize(ps.persistents(), ps.storage());
        check("disk round-trip: persistent 'joins' reloaded from backend",
                joins() == joinsBeforeFlush, joins());
        check("disk round-trip: struct-in-map Duel reloaded from backend (hits kept)",
                duelScore() == hitsBeforeFlush && hitsBeforeFlush > 0, duelScore());
        PersistStore.shutdownActive();

        System.out.println(failures == 0
                ? "[reload-smoke] all checks passed"
                : "[reload-smoke] " + failures + " check(s) FAILED");
        return failures == 0 ? 0 : 1;
    }

    /** Current value of the global persistent {@code joins} counter. */
    private static long joins() {
        Object v = PersistStore.active().get("joins", "");
        return ((Number) v).longValue();
    }

    /**
     * The persisted Duel's reactive {@code hits["n"]} count, read straight out of
     * the persistent {@code duels["arena"]} map — the durable reactive state the
     * instance handler mutates in place.
     */
    private static int duelScore() {
        Object map = PersistStore.active().get("duels", "");
        if (!(map instanceof net.swofty.runtime.MapValue mv)) {
            return -1;
        }
        Object duel = mv.get("arena");
        if (!(duel instanceof net.swofty.structs.StructValue sv)) {
            return -1;
        }
        Object hits = sv.getField("hits");
        if (!(hits instanceof net.swofty.runtime.MapValue hm)) {
            return -1;
        }
        Object n = hm.get("n");
        return n instanceof Number num ? num.intValue() : 0;
    }

    /** Minimal offline PlayerConnection that records nothing beyond the sends. */
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
