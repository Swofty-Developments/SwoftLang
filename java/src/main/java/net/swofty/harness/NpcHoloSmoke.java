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
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.player.PlayerEntityInteractEvent;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.packet.server.play.PlayerInfoRemovePacket;
import net.minestom.server.network.packet.server.play.PlayerInfoUpdatePacket;
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
 * --npc-holo-smoke &lt;compiled.json&gt;: a fake-player proof of the first-class
 * {@code hologram {}} + {@code npc {}} constructs (GROUP C/D). Boots a real
 * MinecraftServer, registers the declared hologram + npc through the SAME
 * runtimes the engine uses, then asserts the observable state:
 *
 * <ul>
 *   <li>a per-viewer hologram renders its {@code ${player.name}} line
 *       differently for each viewer (player bound per stack);</li>
 *   <li>the npc spawns into the world and is NOT a real connection (never
 *       leaks into the ConnectionManager / {@code /tp} suggestions);</li>
 *   <li>a viewer sees the fake-player ADD then a PlayerInfoRemove (in-world,
 *       not in the tab list);</li>
 *   <li>{@code on_click} dispatches through the interact listener;</li>
 *   <li>{@code look_at_players} rotates the head toward the nearest player;</li>
 *   <li>disconnect + remove tear down per-viewer stacks and look tasks with
 *       no leaked entities.</li>
 * </ul>
 */
public final class NpcHoloSmoke {

    private NpcHoloSmoke() {
    }

    private static void stage(String s) {
        System.out.println("[NPCHOLO] .. " + s);
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

        // NB: the server is init()'d, not start()'d — there is no tick loop and
        // the ThreadDispatcher's tick threads are not running, so ticking would
        // block on updateAndAwait. Everything below is driven SYNCHRONOUSLY:
        // TickDispatch.call runs inline (spawns are immediate), renders/dispatch
        // are direct calls, and head-tracking is exercised via the explicit
        // NpcRuntime.lookAt hook (same setView+atan2 path as the look loop).
        int failures = 0;

        // two fake players, positioned for the per-viewer + look-at checks
        stage("spawn players");
        FakeConnection aliceWire = new FakeConnection();
        FakeConnection bobWire = new FakeConnection();
        Player alice = new Player(aliceWire, new GameProfile(UUID.randomUUID(), "Alice"));
        Player bob = new Player(bobWire, new GameProfile(UUID.randomUUID(), "Bob"));
        alice.setInstance(instance, new Pos(12.5, 70, 12.5));
        bob.setInstance(instance, new Pos(200.5, 70, 200.5));

        // Load the compiled declarations and register through the runtimes,
        // exactly as SwoftLangEngine.register() does.
        stage("register hologram + npc");
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
        failures += expect("one hologram declared", 1, parsed.holograms().size());
        failures += expect("one npc declared", 1, parsed.npcs().size());
        failures += expect("hologram detected as per-viewer", true,
                parsed.holograms().get(0).perViewer());

        // ----- the npc must never leak into the connection manager (/tp bug)
        List<String> onlineNames = MinecraftServer.getConnectionManager().getOnlinePlayers()
                .stream().map(Player::getUsername).toList();
        failures += expect("no fake-player leak into the online-player list "
                        + "(the /tp suggestion bug)", true,
                onlineNames.stream().noneMatch(n -> n.toLowerCase().contains("guide")));

        // ----- npc spawned into the world (TickDispatch ran inline at register)
        stage("checking npc spawn");
        Entity npcEntity = NpcRuntime.entity("guide");
        if (npcEntity == null) {
            System.err.println("[NPCHOLO] FAIL npc 'guide' was not registered");
            return failures + 1;
        }
        poll(() -> npcEntity.getInstance() != null, 10_000);
        failures += expect("npc entity spawned into the instance", instance,
                npcEntity.getInstance());
        failures += expect("look-at task is live", true, NpcRuntime.hasLookTask("guide"));

        // ----- per-viewer hologram render: each viewer's stack binds its player
        stage("show per-viewer hologram");
        HologramRuntime.show("info", List.of(alice, bob));
        List<String> aliceLines = HologramRuntime.renderedLinesFor("info", alice);
        List<String> bobLines = HologramRuntime.renderedLinesFor("info", bob);
        failures += expect("alice has a private stack of 3 lines", true,
                aliceLines != null && aliceLines.size() == 3);
        failures += expect("bob has a private stack of 3 lines", true,
                bobLines != null && bobLines.size() == 3);
        if (aliceLines != null && bobLines != null) {
            failures += expect("alice line interpolates her name", true,
                    aliceLines.stream().anyMatch(l -> l.contains("Alice")));
            failures += expect("bob line interpolates his name", true,
                    bobLines.stream().anyMatch(l -> l.contains("Bob")));
            failures += expect("per-viewer stacks differ by viewer", true,
                    !aliceLines.equals(bobLines));
        }
        failures += expect("alice stack has 3 display entities", 3,
                HologramRuntime.displayCountFor("info", alice));
        failures += expect("two live per-viewer stacks", 2,
                HologramRuntime.perViewerStackCount("info"));

        // ----- a viewer sees the fake-player ADD as UNLISTED (in-world, not in
        // the tab list), then a PlayerInfoRemove once it stops viewing.
        stage("addViewer + tablist check");
        npcEntity.addViewer(alice);
        failures += expect("viewer got a PlayerInfoUpdate ADD for the npc", true,
                aliceWire.sawInfoAdd(npcEntity.getUuid()));
        failures += expect("the ADD entry is UNLISTED (npc never shows in the "
                        + "tab list)", true, aliceWire.addWasUnlisted(npcEntity.getUuid()));
        npcEntity.removeViewer(alice);
        failures += expect("stopping viewing sends a PlayerInfoRemove", true,
                aliceWire.sawInfoRemove(npcEntity.getUuid()));

        // ----- on_click dispatches through the interact listener
        stage("on_click dispatch");
        npcEntity.addViewer(alice);
        aliceWire.sent.clear();
        EventDispatcher.call(new PlayerEntityInteractEvent(alice, npcEntity,
                PlayerHand.MAIN, npcEntity.getPosition()));
        failures += expect("on_click ran and messaged the clicker", true,
                aliceWire.sawMessage("Hello"));
        // off-hand interact must NOT re-fire the handler
        aliceWire.sent.clear();
        EventDispatcher.call(new PlayerEntityInteractEvent(alice, npcEntity,
                PlayerHand.OFF, npcEntity.getPosition()));
        failures += expect("off-hand interact does not re-fire on_click", false,
                aliceWire.sawMessage("Hello"));

        // ----- look_at_players rotates the head via the real setView+atan2
        // path. NPC at (5.5,64,5.5), target (12.5,70,12.5): dx=dz=7 -> yaw -45deg,
        // dy=+6 -> pitch tilts up (negative). The nearest-player search
        // (lookNow) additionally runs without error headless.
        stage("look-at");
        failures += expect("head starts at default yaw 0", 0f,
                npcEntity.getPosition().yaw());
        Pos npcPos = npcEntity.getPosition();
        Pos target = new Pos(12.5, 70, 12.5);
        double dx = target.x() - npcPos.x();
        double dz = target.z() - npcPos.z();
        float expectedYaw = (float) Math.toDegrees(Math.atan2(-dx, dz));
        NpcRuntime.lookAt("guide", target);
        Pos looked = npcEntity.getPosition();
        failures += expect("look-at turned the head off its default yaw", true,
                looked.yaw() != 0f);
        failures += expect("look-at yaw faces the target (expected ~"
                        + expectedYaw + ", got " + looked.yaw() + ")", true,
                Math.abs(looked.yaw() - expectedYaw) < 0.5f);
        failures += expect("look-at tilted the pitch up toward the higher target",
                true, looked.pitch() < 0f);
        NpcRuntime.lookNow("guide"); // nearest-player path runs headless w/o error

        // ----- disconnect tears down alice's per-viewer stack, no leak
        stage("disconnect cleanup");
        HologramRuntime.disconnect(alice);
        failures += expect("alice's per-viewer stack destroyed on disconnect "
                        + "(bob's remains)", 1,
                HologramRuntime.perViewerStackCount("info"));

        // ----- remove tears down the npc + cancels the look task
        NpcRuntime.remove("guide");
        poll(npcEntity::isRemoved, 5_000);
        failures += expect("npc entity removed", true, npcEntity.isRemoved());
        failures += expect("look task cancelled on remove", false,
                NpcRuntime.hasLookTask("guide"));

        // ----- hologram remove destroys remaining stacks
        HologramRuntime.remove("info");
        failures += expect("no per-viewer stacks after remove", 0,
                HologramRuntime.perViewerStackCount("info"));

        System.out.println("[NPCHOLO] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    private static void poll(java.util.function.BooleanSupplier cond, long timeoutMillis)
            throws InterruptedException {
        long deadline = System.currentTimeMillis() + timeoutMillis;
        while (System.currentTimeMillis() < deadline && !cond.getAsBoolean()) {
            Thread.sleep(20);
        }
    }


    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[NPCHOLO] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    /** Records outbound packets so per-viewer ADD/Remove + messages can be asserted. */
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

        boolean sawInfoAdd(UUID id) {
            for (SendablePacket packet : sent) {
                if (packet instanceof PlayerInfoUpdatePacket update
                        && update.actions().contains(PlayerInfoUpdatePacket.Action.ADD_PLAYER)) {
                    for (PlayerInfoUpdatePacket.Entry entry : update.entries()) {
                        if (id.equals(entry.uuid())) {
                            return true;
                        }
                    }
                }
            }
            return false;
        }

        boolean addWasUnlisted(UUID id) {
            for (SendablePacket packet : sent) {
                if (packet instanceof PlayerInfoUpdatePacket update
                        && update.actions().contains(PlayerInfoUpdatePacket.Action.ADD_PLAYER)) {
                    for (PlayerInfoUpdatePacket.Entry entry : update.entries()) {
                        if (id.equals(entry.uuid())) {
                            return !entry.listed();
                        }
                    }
                }
            }
            return false;
        }

        boolean sawInfoRemove(UUID id) {
            for (SendablePacket packet : sent) {
                if (packet instanceof PlayerInfoRemovePacket remove
                        && remove.uuids().contains(id)) {
                    return true;
                }
            }
            return false;
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
