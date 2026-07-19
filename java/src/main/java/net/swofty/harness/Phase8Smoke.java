package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicBoolean;

import net.minestom.server.MinecraftServer;
import net.minestom.server.ServerProcess;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.ItemEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.player.PlayerUseItemEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.swofty.InstanceRegistry;
import net.swofty.async.TickClock;
import net.swofty.entities.ScriptEntityRegistry;
import net.swofty.event.EventRegistrar;
import net.swofty.event.EventType;
import net.swofty.fishing.FishingLootRegistry;
import net.swofty.fishing.FishingMedium;
import net.swofty.fishing.FishingRuntime;
import net.swofty.fishing.FishingSession;
import net.swofty.fishing.event.FishBiteEvent;
import net.swofty.fishing.event.PlayerCastRodEvent;
import net.swofty.fishing.event.PlayerCatchFishEvent;
import net.swofty.fishing.event.PlayerReelInEvent;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.FishingLootEntryModel;
import net.swofty.model.FishingLootModel;
import net.swofty.model.MobDefModel;
import net.swofty.model.ServerConfigModel;
import net.swofty.nativebridge.execution.commands.SetPropertyStatement;
import net.swofty.nativebridge.execution.expressions.FunctionCallExpression;
import net.swofty.nativebridge.execution.expressions.StringLiteral;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;
import net.swofty.props.PathResolver;
import net.swofty.props.PropertyTables;

/**
 * Phase-8 headless smoke: a full cast simulation for the native fishing
 * engine under MinecraftServer.init() with a manually driven ticker. A
 * fake player (packet-recording connection) joins a real water instance,
 * casts a genuine fishing rod through the same Minestom use-item event
 * the engine listens on, and the smoke asserts the whole arc: cancelled
 * cast (no bobber), FishingSession + bobber-pair spawn, throw physics
 * down into the water, the surface settle, the bite inside the
 * configured window, reel-during-bite loot resolution (item catch swaps
 * through a script-registered PlayerCatchFish handler and flies as an
 * ItemEntity; mob catch spawns the registry mob aggroed on the fisher),
 * per-catch messages on the wire, and session/entity cleanup.
 *
 * Invoked directly (java net.swofty.harness.Phase8Smoke): keeping
 * ExecHarness untouched keeps every prior baseline capture (which
 * embeds ExecHarness stack-trace line numbers) byte-identical.
 * MinecraftServer.init() starts non-daemon threads, so main() always
 * exits explicitly.
 */
public final class Phase8Smoke {
    /** Bite window under test: 2..4 ticks so the smoke stays fast. */
    private static final int MIN_BITE = 2;
    private static final int MAX_BITE = 4;
    private static final int SETTLE_TIMEOUT_TICKS = 200;
    /** Scheduling slack on top of MAX_BITE (TickClock drains at tick end). */
    private static final int BITE_SLACK_TICKS = 4;

    private Phase8Smoke() {
    }

    public static void main(String[] args) {
        int code;
        try {
            code = run();
        } catch (Throwable t) {
            t.printStackTrace();
            code = 1;
        }
        System.exit(code);
    }

    public static int run() throws Exception {
        MinecraftServer ignored = MinecraftServer.init();
        // the default handler logs through slf4j (a no-op provider in the
        // harness): surface engine-thread exceptions on stderr instead
        MinecraftServer.getExceptionManager()
                .setExceptionHandler(Throwable::printStackTrace);
        PropertyTables.ensureRegistered();
        TickClock.init();

        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        instance.setGenerator(unit -> {
            unit.modifier().fillHeight(0, 38, Block.STONE);
            unit.modifier().fillHeight(38, 40, Block.WATER);
        });
        instance.loadChunk(0, 0).join();
        InstanceRegistry.register("world", instance);

        FishingRuntime.init(new ServerConfigModel("offline", null, "0.0.0.0",
                25565, null, null, null, -1, "127.0.0.1", null, false,
                MIN_BITE, MAX_BITE));

        ServerProcess.Ticker ticker = MinecraftServer.process().ticker();

        // fake player: packets land in a recording connection; looking
        // steeply down so the throw arcs into the pool fast
        FakeConnection wire = new FakeConnection();
        Player fisher = new Player(wire, new GameProfile(UUID.randomUUID(), "Fisher"));
        var joined = fisher.setInstance(instance, new Pos(0.5, 45, 0.5, 0f, 80f));
        for (int t = 0; t < 100 && !joined.isDone(); t++) {
            tick(ticker);
        }
        int failures = 0;
        failures += expect("fake player joined the instance", true,
                fisher.getInstance() == instance);
        fisher.setItemInMainHand(ItemStack.of(Material.FISHING_ROD));

        // event observers (raw listeners observe; script handlers act)
        Deliveries deliveries = new Deliveries();
        deliveries.listen();

        // script-registered PlayerCatchFish handler through the REAL
        // registrar: swap every caught item to a salmon
        Event catchScript = new Event("PlayerCatchFish");
        ExecuteBlock catchBlock = new ExecuteBlock();
        catchBlock.addStatement(new SetPropertyStatement(
                new VariableReference("event"), "caught_item",
                new FunctionCallExpression("item",
                        List.of(new StringLiteral("SALMON")))));
        catchScript.setExecuteBlock(catchBlock);
        new EventRegistrar().registerEvent(catchScript);

        failures += curatedIdentityChecks();
        failures += cancelledCastChecks(ticker, fisher, deliveries);
        FishingSession session = null;
        int settledTick = -1;
        {
            CastResult cast = castAndSettle(ticker, fisher, deliveries);
            failures += cast.failures;
            session = cast.session;
            settledTick = cast.settledTick;
        }
        if (session != null && settledTick >= 0) {
            failures += biteChecks(ticker, session, deliveries);
            failures += itemCatchChecks(ticker, fisher, wire, instance, deliveries);
        } else {
            failures++;
        }
        failures += mobCatchChecks(ticker, fisher, instance, deliveries);
        failures += cleanupChecks(ticker, fisher);

        System.out.println("[PHASE8-SMOKE] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // curated identifiers stay wired
    // ------------------------------------------------------------------

    private static int curatedIdentityChecks() {
        int failures = 0;
        for (String name : List.of("PlayerCastRod", "FishBite", "PlayerCatchFish",
                "PlayerReelIn")) {
            if (EventType.fromIdentifier(name) == null) {
                System.err.println("[PHASE8-SMOKE] FAIL '" + name
                        + "' is not a curated event identifier");
                failures++;
            }
        }
        System.out.println("[PHASE8-SMOKE] curated identifiers: "
                + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // a cancelled PlayerCastRod never spawns a bobber
    // ------------------------------------------------------------------

    private static int cancelledCastChecks(ServerProcess.Ticker ticker, Player fisher,
            Deliveries deliveries) {
        int failures = 0;
        deliveries.cancelNextCast.set(true);
        useRod(fisher);
        failures += expect("cast event delivered", 1, deliveries.casts.size());
        failures += expect("cancelled cast leaves no session", true,
                FishingRuntime.session(fisher.getUuid()) == null);
        failures += expect("cancelled cast tracks no entities", 0,
                ScriptEntityRegistry.count());
        tick(ticker); // a fresh alive-tick so the next rod use is not deduped
        System.out.println("[PHASE8-SMOKE] cancelled cast: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // real cast: session + bobber pair + throw physics + water settle
    // ------------------------------------------------------------------

    private record CastResult(int failures, FishingSession session, int settledTick) {
    }

    private static CastResult castAndSettle(ServerProcess.Ticker ticker, Player fisher,
            Deliveries deliveries) {
        int failures = 0;
        useRod(fisher);
        FishingSession session = FishingRuntime.session(fisher.getUuid());
        if (session == null) {
            System.err.println("[PHASE8-SMOKE] FAIL rod use created no session");
            return new CastResult(failures + 1, null, -1);
        }
        failures += expect("session owner", true, session.player() == fisher);
        failures += expect("bobber pair tracked (hook + controller)", 2,
                ScriptEntityRegistry.count());
        double eyeY = fisher.getPosition().y() + fisher.getEyeHeight();
        if (Math.abs(session.bobber().position().y() - eyeY) > 0.5) {
            System.err.println("[PHASE8-SMOKE] FAIL bobber should start at eye height "
                    + eyeY + ", got " + session.bobber().position());
            failures++;
        }
        failures += expect("mid-flight has no medium", true,
                session.bobber().medium() == null);

        int settledTick = -1;
        for (int t = 1; t <= SETTLE_TIMEOUT_TICKS; t++) {
            tick(ticker);
            if (session.bobber().medium() != null) {
                settledTick = t;
                break;
            }
        }
        if (settledTick < 0) {
            System.err.println("[PHASE8-SMOKE] FAIL bobber never settled in "
                    + SETTLE_TIMEOUT_TICKS + " ticks; pos "
                    + session.bobber().position());
            return new CastResult(failures + 1, session, -1);
        }
        failures += expect("settled medium", FishingMedium.WATER,
                session.bobber().medium());
        double surfaceY = session.bobber().position().y();
        if (surfaceY < 39.5 || surfaceY > 40.1) {
            System.err.println("[PHASE8-SMOKE] FAIL settle height should hug the "
                    + "y=40 water surface, got " + surfaceY);
            failures++;
        }
        failures += expect("no bite before the window", false, session.isBiteReady());
        System.out.println("[PHASE8-SMOKE] cast+settle: " + (failures == 0
                ? "PASS (settled tick " + settledTick + " at y=" + surfaceY + ")"
                : failures + " failure(s)"));
        return new CastResult(failures, session, settledTick);
    }

    // ------------------------------------------------------------------
    // the bite arrives inside the configured window, with the event
    // ------------------------------------------------------------------

    private static int biteChecks(ServerProcess.Ticker ticker, FishingSession session,
            Deliveries deliveries) {
        int failures = 0;
        int biteAfter = -1;
        for (int t = 1; t <= MAX_BITE + BITE_SLACK_TICKS; t++) {
            tick(ticker);
            if (session.isBiteReady()) {
                biteAfter = t;
                break;
            }
        }
        if (biteAfter < 0) {
            System.err.println("[PHASE8-SMOKE] FAIL no bite within "
                    + (MAX_BITE + BITE_SLACK_TICKS) + " ticks of settling");
            return failures + 1;
        }
        // scheduling happens mid-tick and the TickClock drains at tick
        // end, so the earliest observable bite is one loop tick early
        if (biteAfter < MIN_BITE - 1) {
            System.err.println("[PHASE8-SMOKE] FAIL bite after " + biteAfter
                    + " tick(s), before the " + MIN_BITE + "-tick minimum");
            failures++;
        }
        failures += expect("FishBite delivered", 1, deliveries.bites.size());
        if (!deliveries.bites.isEmpty()) {
            FishBiteEvent bite = deliveries.bites.get(0);
            failures += expect("bite player", true, bite.getPlayer() == session.player());
            if (bite.getHookLocation().distance(session.bobber().position()) > 1.0) {
                System.err.println("[PHASE8-SMOKE] FAIL bite hook_location "
                        + bite.getHookLocation() + " far from bobber "
                        + session.bobber().position());
                failures++;
            }
            // the typed wrapper row scripts read (same machinery, live value)
            Object row = PathResolver.getProperty(
                    new net.swofty.event.events.SwoftFishBiteEvent(bite,
                            new Event("FishBite")), "hook_location", 0, 0);
            failures += expect("hook_location wrapper row", bite.getHookLocation(), row);
        }
        System.out.println("[PHASE8-SMOKE] bite: " + (failures == 0
                ? "PASS (after " + biteAfter + " tick(s) in [" + (MIN_BITE - 1) + ", "
                        + (MAX_BITE + BITE_SLACK_TICKS) + "])"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // reel during the bite: weighted roll -> script swap -> flying item
    // ------------------------------------------------------------------

    private static int itemCatchChecks(ServerProcess.Ticker ticker, Player fisher,
            FakeConnection wire, InstanceContainer instance, Deliveries deliveries) {
        int failures = 0;
        FishingLootRegistry.clear();
        FishingLootRegistry.register(new FishingLootModel("smoke_water", "water", null,
                List.of(new FishingLootEntryModel("item", "COD", 1,
                        "<yellow>Fresh from the pool!")), -1, -1));

        useRod(fisher);
        failures += expect("reel event delivered", 1, deliveries.reels.size());
        failures += expect("catch event delivered", 1, deliveries.catches.size());
        failures += expect("reel-during-bite cleared the session", true,
                FishingRuntime.session(fisher.getUuid()) == null);
        if (!deliveries.catches.isEmpty()) {
            PlayerCatchFishEvent caught = deliveries.catches.get(0);
            failures += expect("catch is an item catch", true,
                    caught.getCaughtMob() == null);
            failures += expect("script handler swapped the caught item",
                    Material.SALMON, caught.getCaughtItem() != null
                            ? caught.getCaughtItem().material() : null);
        }

        // the swapped stack must be the one flying to the player
        ItemEntity flying = null;
        for (int t = 0; t < 20 && flying == null; t++) {
            for (Entity entity : instance.getEntities()) {
                if (entity instanceof ItemEntity itemEntity) {
                    flying = itemEntity;
                }
            }
            if (flying == null) {
                tick(ticker);
            }
        }
        if (flying == null) {
            System.err.println("[PHASE8-SMOKE] FAIL no ItemEntity flew after the catch");
            failures++;
        } else {
            failures += expect("flying stack is the swapped salmon", Material.SALMON,
                    flying.getItemStack().material());
            if (!(flying.getVelocity().y() > 0)) {
                System.err.println("[PHASE8-SMOKE] FAIL catch should fly with upward "
                        + "lift, velocity " + flying.getVelocity());
                failures++;
            }
            flying.remove();
        }
        failures += expect("per-catch message reached the wire", true,
                wire.sawMessage("Fresh from the pool!"));
        failures += expect("bobber pair reclaimed after the reel", 0,
                ScriptEntityRegistry.count());
        System.out.println("[PHASE8-SMOKE] item catch: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // mob catches spawn the registry mob at the hook, aggroed
    // ------------------------------------------------------------------

    private static int mobCatchChecks(ServerProcess.Ticker ticker, Player fisher,
            InstanceContainer instance, Deliveries deliveries) {
        int failures = 0;
        MobRegistry.register(new MobDefModel("sea_walker", "ZOMBIE",
                new StringLiteral("Sea Walker"), 40, 2, 0.25, "melee",
                List.of(), null, null, null, null));
        FishingLootRegistry.clear();
        FishingLootRegistry.register(new FishingLootModel("smoke_sea", "water", null,
                List.of(new FishingLootEntryModel("mob", "sea_walker", 1, null)), -1, -1));

        tick(ticker); // fresh alive-tick for the new rod use
        useRod(fisher);
        FishingSession session = FishingRuntime.session(fisher.getUuid());
        if (session == null) {
            System.err.println("[PHASE8-SMOKE] FAIL second cast created no session");
            return failures + 1;
        }
        for (int t = 0; t < SETTLE_TIMEOUT_TICKS + MAX_BITE + BITE_SLACK_TICKS; t++) {
            tick(ticker);
            if (session.isBiteReady()) {
                break;
            }
        }
        if (!session.isBiteReady()) {
            System.err.println("[PHASE8-SMOKE] FAIL second cast never reached a bite");
            return failures + 1;
        }
        tick(ticker);
        useRod(fisher);

        failures += expect("mob catch event delivered", 2, deliveries.catches.size());
        SwoftMob sea = null;
        for (int t = 0; t < 20 && sea == null; t++) {
            for (Entity entity : instance.getEntities()) {
                if (entity instanceof SwoftMob mob) {
                    sea = mob;
                }
            }
            if (sea == null) {
                tick(ticker);
            }
        }
        if (sea == null) {
            System.err.println("[PHASE8-SMOKE] FAIL mob catch spawned no SwoftMob");
            failures++;
        } else {
            failures += expect("sea creature aggroes the fisher", true,
                    sea.getTarget() == fisher);
            if (sea.getPosition().distance(fisher.getPosition()) < 1.0) {
                System.err.println("[PHASE8-SMOKE] FAIL sea creature should spawn at "
                        + "the hook, not on the fisher: " + sea.getPosition());
                failures++;
            }
        }
        MobRegistry.clear(); // removes the live mob too (phase-7 semantics)
        FishingLootRegistry.clear();
        System.out.println("[PHASE8-SMOKE] mob catch: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // reset() sweeps sessions and bobbers
    // ------------------------------------------------------------------

    private static int cleanupChecks(ServerProcess.Ticker ticker, Player fisher) {
        int failures = 0;
        tick(ticker); // fresh alive-tick so this rod use is not deduped
        useRod(fisher); // dangling cast on purpose
        failures += expect("dangling cast live", true,
                FishingRuntime.session(fisher.getUuid()) != null);
        FishingRuntime.reset();
        failures += expect("reset cleared the session", true,
                FishingRuntime.session(fisher.getUuid()) == null);
        failures += expect("reset reclaimed the bobber pair", 0,
                ScriptEntityRegistry.count());
        System.out.println("[PHASE8-SMOKE] cleanup: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    /** One manual server tick; a short sleep keeps tick timings sane. */
    private static void tick(ServerProcess.Ticker ticker) {
        ticker.tick(System.nanoTime());
        try {
            Thread.sleep(2);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    /** The same engine entry a physical right click reaches. */
    private static void useRod(Player fisher) {
        EventDispatcher.call(new PlayerUseItemEvent(fisher, PlayerHand.MAIN,
                fisher.getItemInMainHand(), 0));
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[PHASE8-SMOKE] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    /** Raw observers for the four typed events + one-shot cast cancel. */
    private static final class Deliveries {
        final List<PlayerCastRodEvent> casts = new CopyOnWriteArrayList<>();
        final List<FishBiteEvent> bites = new CopyOnWriteArrayList<>();
        final List<PlayerCatchFishEvent> catches = new CopyOnWriteArrayList<>();
        final List<PlayerReelInEvent> reels = new CopyOnWriteArrayList<>();
        final AtomicBoolean cancelNextCast = new AtomicBoolean();

        void listen() {
            var handler = MinecraftServer.getGlobalEventHandler();
            handler.addListener(PlayerCastRodEvent.class, event -> {
                casts.add(event);
                if (cancelNextCast.compareAndSet(true, false)) {
                    event.setCancelled(true);
                }
            });
            handler.addListener(FishBiteEvent.class, bites::add);
            handler.addListener(PlayerCatchFishEvent.class, catches::add);
            handler.addListener(PlayerReelInEvent.class, reels::add);
        }
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
}
