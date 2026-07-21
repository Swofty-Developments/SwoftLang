package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Pos;
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
import net.swofty.event.EventRegistrar;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.MobDefModel;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.PropertyTables;

/**
 * --mob-override-smoke &lt;compiled.json&gt;: a fake-player proof that a mob's
 * DEDICATED {@code on_hit}/{@code on_death} fields participate in the OOP
 * override protocol against a base {@code Mob {}} receiver method.
 *
 * <p>The bug this locks down: a dedicated mob handler that overrides a base
 * receiver method (e.g. {@code mob "id" { on_hit(a) { ... default() } }}) is
 * type-checked as an override, but at runtime {@code default()} used to fall
 * through to the builtin because {@code $override} was never bound, so the base
 * {@code Mob.on_hit} never chained. The fix routes the dedicated handlers
 * through {@link net.swofty.handlers.HandlerDispatch#runOverride} and teaches
 * {@code ReceiverDispatch.isOverridden} that a dedicated field is an override,
 * so the base receiver event does not ALSO double-fire.
 *
 * <p>Asserts, driving the real melee/kill pipeline (handleMeleeHit -&gt;
 * damage() -&gt; MobDamageEvent -&gt; base receiver):
 * <ul>
 *   <li>plain mob (no custom on_hit) -&gt; only the base A runs;</li>
 *   <li>custom on_hit with {@code default()} -&gt; B THEN the base A, exactly
 *       once (no double-fire), with {@code this} = the overriding mob threaded
 *       into the base body;</li>
 *   <li>custom on_hit WITHOUT {@code default()} -&gt; only B (base suppressed);</li>
 *   <li>custom on_death whose base declares no on_death -&gt; {@code default()}
 *       is a safe no-op.</li>
 * </ul>
 */
public final class MobOverrideSmoke {

    private static final Pattern TRACE = Pattern.compile("TRACE=([A-Za-z0-9_:]+)");

    private MobOverrideSmoke() {
    }

    private static void stage(String s) {
        System.out.println("[MOBOVR] .. " + s);
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

        stage("register decls + base receiver");
        ParsedScript parsed = SwoftJsonLoader.load(Files.readString(Path.of(jsonPath)));
        for (MobDefModel mob : parsed.mobs()) {
            MobRegistry.register(mob);
        }
        // Register the base `Mob {}` receiver methods exactly as the engine does
        // (indexes the base body for default()/super AND attaches the MobDamage
        // listener that fires the base for non-overriding mobs).
        EventRegistrar registrar = new EventRegistrar();
        for (Event event : parsed.events()) {
            registrar.registerEvent(event);
        }

        stage("spawn player");
        FakeConnection wire = new FakeConnection();
        Player alice = new Player(wire, new GameProfile(UUID.randomUUID(), "Alice"));
        alice.setInstance(instance, new Pos(0.5, 65, 0.5)).join();

        SwoftMob critter = MobRegistry.spawn("critter", new Pos(5.5, 65, 0.5), instance);
        SwoftMob ghoulD = MobRegistry.spawn("ghoul_d", new Pos(6.5, 65, 0.5), instance);
        SwoftMob ghoulN = MobRegistry.spawn("ghoul_n", new Pos(7.5, 65, 0.5), instance);
        SwoftMob ghoulX = MobRegistry.spawn("ghoul_x", new Pos(8.5, 65, 0.5), instance);

        // ================================================================
        // 1) plain mob: hitting it runs ONLY the base A
        // ================================================================
        stage("plain mob -> only base A");
        wire.sent.clear();
        critter.handleMeleeHit(alice);
        List<String> t1 = wire.trace();
        failures += expectSeq("plain mob runs only base A", List.of("BASE_A:critter"), t1);

        // ================================================================
        // 2) custom on_hit + default(): B THEN base A, exactly once
        // ================================================================
        stage("custom on_hit + default() -> B then A (once)");
        wire.sent.clear();
        ghoulD.handleMeleeHit(alice);
        List<String> t2 = wire.trace();
        failures += expectSeq("B runs THEN base A, exactly once (this=ghoul_d threaded to base)",
                List.of("CUST_B:ghoul_d", "BASE_A:ghoul_d"), t2);

        // ================================================================
        // 3) custom on_hit WITHOUT default(): only B (base suppressed)
        // ================================================================
        stage("custom on_hit no default() -> only B");
        wire.sent.clear();
        ghoulN.handleMeleeHit(alice);
        List<String> t3 = wire.trace();
        failures += expectSeq("base suppressed when override omits default()",
                List.of("CUST_ONLY:ghoul_n"), t3);

        // ================================================================
        // 4) custom on_death, base has no on_death: default() is a safe no-op
        // ================================================================
        stage("default() with no base method -> safe no-op");
        // register alice as the last damager so kill() resolves killer = alice
        ghoulX.handleMeleeHit(alice);
        wire.sent.clear();
        ghoulX.kill();
        List<String> t4 = wire.trace();
        failures += expectSeq("dedicated override runs; default() no-ops (no base on_death)",
                List.of("NOBASE_DEATH:ghoul_x"), t4);

        System.out.println("[MOBOVR] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    private static int expectSeq(String what, List<String> expected, List<String> actual) {
        if (expected.equals(actual)) {
            System.out.println("[MOBOVR] ok   " + what + " -> " + actual);
            return 0;
        }
        System.err.println("[MOBOVR] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    /** Records outbound packets so broadcast/chat order can be asserted. */
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

        /** The TRACE=... markers seen, in packet (fire) order. */
        List<String> trace() {
            List<String> out = new ArrayList<>();
            for (SendablePacket packet : sent) {
                Matcher m = TRACE.matcher(String.valueOf(packet));
                while (m.find()) {
                    out.add(m.group(1));
                }
            }
            return out;
        }
    }
}
