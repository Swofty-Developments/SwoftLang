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
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.swofty.InstanceRegistry;
import net.swofty.async.TickClock;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.holograms.HologramRuntime;
import net.swofty.model.HologramModel;
import net.swofty.model.NpcModel;
import net.swofty.npcs.NpcRuntime;
import net.swofty.props.PropertyTables;

/**
 * --npc-viewers-smoke &lt;compiled.json&gt;: a fake-player proof of the NEW
 * per-viewer NPC + on_tick features (W-viewers §2 / on_tick), driven against
 * {@code npc_viewers_smoke.sw}:
 *
 * <ul>
 *   <li>an npc with {@code viewable: false} spawns with auto-view OFF and ZERO
 *       viewers even though players share the instance;</li>
 *   <li>{@code show npc "sentry" to p1} (name-keyed, via the same Viewable
 *       add-viewer path) reveals it to p1 ONLY;</li>
 *   <li>{@code viewers of npc "sentry"} reflects the live viewer set;</li>
 *   <li>{@code hide npc "sentry" from p1} removes p1;</li>
 *   <li>the npc never leaks into the ConnectionManager online-player list;</li>
 *   <li>the npc's {@code on_tick} fires (a manual tick sets {@code this.glowing
 *       = true} on the fake-player entity);</li>
 *   <li>a hologram that declares {@code on_tick} gets a per-tick task (a
 *       hologram that does NOT declare it gets none — guard proof), and running
 *       that on_tick mutates the bound text-display ({@code this.text}).</li>
 * </ul>
 */
public final class NpcViewersSmoke {

    private NpcViewersSmoke() {
    }

    private static void stage(String s) {
        System.out.println("[NPCVIEW] .. " + s);
        System.out.flush();
    }

    public static int run(String jsonPath) throws Exception {
        stage("init server");
        MinecraftServer.init();
        MinecraftServer.getExceptionManager().setExceptionHandler(Throwable::printStackTrace);
        PropertyTables.ensureRegistered();
        TickClock.init();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> unit.modifier().fillHeight(0, 64, Block.STONE));
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        int failures = 0;

        // two fake players IN the instance, so an auto-viewable npc WOULD see
        // them — proving viewable:false is what keeps them off the viewer set.
        stage("spawn players");
        FakeConnection p1Wire = new FakeConnection();
        FakeConnection p2Wire = new FakeConnection();
        Player p1 = new Player(p1Wire, new GameProfile(UUID.randomUUID(), "P1"));
        Player p2 = new Player(p2Wire, new GameProfile(UUID.randomUUID(), "P2"));
        p1.setInstance(instance, new Pos(0.5, 65, 0.5)).join();
        p2.setInstance(instance, new Pos(1.5, 65, 0.5)).join();

        // register the compiled decls, exactly as the engine does
        stage("register holograms + npc");
        ParsedScript parsed = SwoftJsonLoader.load(Files.readString(Path.of(jsonPath)));
        HologramRuntime.init();
        HologramRuntime.teardown();
        for (HologramModel holo : parsed.holograms()) {
            HologramRuntime.register(holo);
        }
        NpcRuntime.init();
        NpcRuntime.teardown();
        for (NpcModel npc : parsed.npcs()) {
            NpcRuntime.register(npc);
        }

        // ----- viewable:false => auto-view OFF, zero viewers at spawn
        stage("viewable:false => 0 viewers");
        Entity sentry = NpcRuntime.entity("sentry");
        if (sentry == null) {
            System.err.println("[NPCVIEW] FAIL npc 'sentry' was not registered");
            return failures + 1;
        }
        failures += expect("npc spawned into the instance", instance, sentry.getInstance());
        failures += expect("viewable:false => not auto-viewable", false,
                sentry.isAutoViewable());
        failures += expect("viewable:false => zero viewers at spawn", 0,
                sentry.getViewers().size());
        failures += expect("viewers of npc reflects zero", 0,
                NpcRuntime.viewersOf("sentry").size());

        // ----- the npc must never leak into the connection manager
        List<String> online = MinecraftServer.getConnectionManager().getOnlinePlayers()
                .stream().map(Player::getUsername).toList();
        failures += expect("no fake-player leak into the online-player list", true,
                online.stream().noneMatch(n -> n.toLowerCase().contains("sentry")));

        // ----- show npc "sentry" to p1 => exactly one viewer, p1
        stage("show npc \"sentry\" to p1");
        NpcRuntime.show("sentry", p1);
        failures += expect("show => one viewer", 1, sentry.getViewers().size());
        failures += expect("the viewer is p1", true, sentry.getViewers().contains(p1));
        failures += expect("p2 is NOT a viewer", false, sentry.getViewers().contains(p2));
        List<Player> viewers = NpcRuntime.viewersOf("sentry");
        failures += expect("viewers of npc = [p1]", true,
                viewers.size() == 1 && viewers.contains(p1));
        failures += expect("p1 got a PlayerInfo ADD (fake player revealed in-world)",
                true, p1Wire.sawAnyPacket());

        // ----- hide npc "sentry" from p1 => removed
        stage("hide npc \"sentry\" from p1");
        NpcRuntime.hide("sentry", p1);
        failures += expect("hide => p1 no longer a viewer", false,
                sentry.getViewers().contains(p1));
        failures += expect("viewers of npc back to zero", 0,
                NpcRuntime.viewersOf("sentry").size());

        // ----- npc on_tick fires: `set this.glowing to true` on a manual tick
        stage("npc on_tick fires");
        failures += expect("npc not glowing before a tick", false, sentry.isGlowing());
        sentry.tick(0L);
        failures += expect("npc on_tick set this.glowing = true", true, sentry.isGlowing());

        // ----- hologram on_tick: task scheduled iff declared (guard), and it
        // mutates the bound text display when run.
        stage("hologram on_tick guard + fire");
        failures += expect("hologram with on_tick has a per-tick task", true,
                HologramRuntime.hasTickTask("clock"));
        failures += expect("hologram WITHOUT on_tick has no per-tick task", false,
                HologramRuntime.hasTickTask("static_sign"));
        HologramRuntime.show("clock", p1);
        String tickedText = HologramRuntime.tickOnceForTest("clock");
        failures += expect("hologram on_tick mutated this.text to 'ticked'",
                "ticked", tickedText);

        // ----- teardown cancels the tick task (no leak)
        stage("teardown clears tick tasks");
        HologramRuntime.teardown();
        failures += expect("teardown removed the hologram tick task", false,
                HologramRuntime.hasTickTask("clock"));

        System.out.println("[NPCVIEW] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[NPCVIEW] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    /** Records outbound packets so the reveal ADD can be asserted. */
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

        boolean sawAnyPacket() {
            return !sent.isEmpty();
        }
    }
}
