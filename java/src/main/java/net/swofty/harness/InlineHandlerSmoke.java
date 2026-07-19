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
import net.minestom.server.event.entity.EntityAttackEvent;
import net.minestom.server.event.item.ItemDropEvent;
import net.minestom.server.event.player.PlayerEntityInteractEvent;
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
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.handlers.InlineHandlerRuntime;
import net.swofty.holograms.HologramRuntime;
import net.swofty.items.ItemRegistry;
import net.swofty.mobs.MobRegistry;
import net.swofty.mobs.MobRuntime;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.HologramModel;
import net.swofty.model.ItemDefModel;
import net.swofty.model.MobDefModel;
import net.swofty.props.PropertyTables;

/**
 * --inline-handlers-smoke &lt;compiled.json&gt;: a fake-player proof of the
 * generalized first-class inline-handler dispatch (W-inline-handlers). Boots a
 * real MinecraftServer, registers the declared items/mobs/holograms through the
 * SAME registries + {@link InlineHandlerRuntime} the engine uses, then fires the
 * concrete Minestom events and asserts:
 *
 * <ul>
 *   <li>each handler runs with the correct bindings — {@code this} = the acted
 *       ItemStack (its tags) / hit Mob (its custom_id), the params = the actor
 *       + event args;</li>
 *   <li>an item/mob handler fires ONLY for its declaration id — a handler-free
 *       item (plain_stick), a vanilla stack, and a handler-free mob (critter)
 *       never trigger magic_wand / boss;</li>
 *   <li>a cancellable handler (on_right_click) vetoes the underlying
 *       PlayerUseItemEvent via {@code cancel event};</li>
 *   <li>the dedicated mob {@code on_hit} path still works;</li>
 *   <li>off-hand interacts do not re-fire on_click.</li>
 * </ul>
 */
public final class InlineHandlerSmoke {

    private InlineHandlerSmoke() {
    }

    private static void stage(String s) {
        System.out.println("[INLINE] .. " + s);
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

        // ---- register declarations exactly as SwoftLangEngine.register() does
        stage("register decls");
        ParsedScript parsed = SwoftJsonLoader.load(Files.readString(Path.of(jsonPath)));
        for (ItemDefModel item : parsed.items()) {
            ItemRegistry.register(item);
        }
        for (MobDefModel mob : parsed.mobs()) {
            MobRegistry.register(mob);
        }
        HologramRuntime.init();
        HologramRuntime.teardown();
        for (HologramModel holo : parsed.holograms()) {
            HologramRuntime.register(holo);
        }
        MobRuntime.init();
        InlineHandlerRuntime.init();
        // idempotent init: a second call must NOT double-register listeners
        InlineHandlerRuntime.init();
        InlineHandlerRuntime.teardown();

        // ---- two fake players
        stage("spawn players");
        FakeConnection aliceWire = new FakeConnection();
        FakeConnection bobWire = new FakeConnection();
        Player alice = new Player(aliceWire, new GameProfile(UUID.randomUUID(), "Alice"));
        Player bob = new Player(bobWire, new GameProfile(UUID.randomUUID(), "Bob"));
        alice.setInstance(instance, new Pos(0.5, 65, 0.5)).join();
        bob.setInstance(instance, new Pos(2.5, 65, 0.5)).join();

        ItemStack wand = ItemRegistry.build("magic_wand", 1);
        ItemStack plainStick = ItemRegistry.build("plain_stick", 1);
        ItemStack vanilla = ItemStack.of(Material.STICK);

        // ================================================================
        // ITEM on_right_click: dispatch + this/tags binding + cancel veto
        // ================================================================
        stage("item on_right_click");
        aliceWire.sent.clear();
        PlayerUseItemEvent useWand =
                new PlayerUseItemEvent(alice, PlayerHand.MAIN, wand, 0);
        EventDispatcher.call(useWand);
        failures += expect("on_right_click ran with player+this.tags bound", true,
                aliceWire.saw("rc:Alice:42"));
        failures += expect("cancellable on_right_click vetoed PlayerUseItemEvent", true,
                useWand.isCancelled());

        // the SAME handler fires for a different actor with THAT actor bound
        bobWire.sent.clear();
        EventDispatcher.call(new PlayerUseItemEvent(bob, PlayerHand.MAIN, wand, 0));
        failures += expect("on_right_click binds the acting player (Bob)", true,
                bobWire.saw("rc:Bob:42"));

        // ---- id filter: handler-free custom item must NOT fire magic_wand
        stage("id filter: plain_stick + vanilla");
        aliceWire.sent.clear();
        PlayerUseItemEvent useStick =
                new PlayerUseItemEvent(alice, PlayerHand.MAIN, plainStick, 0);
        EventDispatcher.call(useStick);
        failures += expect("handler-free item does not fire magic_wand's handler", false,
                aliceWire.saw("rc:"));
        failures += expect("handler-free item's use is NOT cancelled", false,
                useStick.isCancelled());

        // ---- id filter: a vanilla stack must NOT fire either
        aliceWire.sent.clear();
        PlayerUseItemEvent useVanilla =
                new PlayerUseItemEvent(alice, PlayerHand.MAIN, vanilla, 0);
        EventDispatcher.call(useVanilla);
        failures += expect("vanilla stack does not fire any item handler", false,
                aliceWire.saw("rc:"));
        failures += expect("vanilla stack use is NOT cancelled", false,
                useVanilla.isCancelled());

        // ---- an item that declares on_right_click but NOT on_drop: on_drop
        //      must no-op (event stays uncancelled)
        ItemDropEvent dropWand = new ItemDropEvent(alice, wand);
        EventDispatcher.call(dropWand);
        failures += expect("undeclared on_drop no-ops (event not cancelled)", false,
                dropWand.isCancelled());

        // ================================================================
        // ITEM on_attack_entity: this + player + target binding, held-item filter
        // ================================================================
        stage("item on_attack_entity");
        SwoftMob critter = MobRegistry.spawn("critter", new Pos(5.5, 65, 0.5), instance);
        SwoftMob boss = MobRegistry.spawn("boss", new Pos(6.5, 65, 0.5), instance);

        alice.setItemInHand(PlayerHand.MAIN, wand);
        aliceWire.sent.clear();
        EventDispatcher.call(new EntityAttackEvent(alice, critter));
        failures += expect("on_attack_entity ran with player bound", true,
                aliceWire.saw("atk:Alice:"));
        failures += expect("on_attack_entity target bound (a chicken)", true,
                aliceWire.lowerSaw("chicken"));

        // held plain_stick -> no on_attack_entity
        alice.setItemInHand(PlayerHand.MAIN, plainStick);
        aliceWire.sent.clear();
        EventDispatcher.call(new EntityAttackEvent(alice, critter));
        failures += expect("holding a handler-free item fires no on_attack_entity", false,
                aliceWire.saw("atk:"));
        alice.setItemInHand(PlayerHand.MAIN, ItemStack.AIR);

        // ================================================================
        // MOB on_click: this = mob (custom_id), player bound; id filter
        // ================================================================
        stage("mob on_click");
        aliceWire.sent.clear();
        EventDispatcher.call(new PlayerEntityInteractEvent(alice, boss,
                PlayerHand.MAIN, boss.getPosition()));
        failures += expect("mob on_click ran with player+this.custom_id bound", true,
                aliceWire.saw("poke:Alice:boss"));

        // off-hand interact must NOT re-fire
        aliceWire.sent.clear();
        EventDispatcher.call(new PlayerEntityInteractEvent(alice, boss,
                PlayerHand.OFF, boss.getPosition()));
        failures += expect("off-hand interact does not re-fire mob on_click", false,
                aliceWire.saw("poke:"));

        // handler-free mob must NOT fire boss's handler
        aliceWire.sent.clear();
        EventDispatcher.call(new PlayerEntityInteractEvent(alice, critter,
                PlayerHand.MAIN, critter.getPosition()));
        failures += expect("clicking a handler-free mob fires nothing", false,
                aliceWire.saw("poke:"));

        // ================================================================
        // MOB on_hit (dedicated path) still works; then on_death killer bound
        // ================================================================
        stage("mob on_hit + on_death");
        aliceWire.sent.clear();
        boss.handleMeleeHit(alice); // registers alice as last damager, runs on_hit
        failures += expect("dedicated on_hit still fires with attacker bound", true,
                aliceWire.saw("hit:Alice"));

        aliceWire.sent.clear();
        boss.kill(); // killer resolved from the last damage source (alice)
        failures += expect("on_death fires with killer bound", true,
                aliceWire.saw("death:Alice"));

        // ================================================================
        // HOLOGRAM on_click via the interact packet
        // ================================================================
        stage("hologram on_click");
        HologramRuntime.show("shop", List.of(alice));
        Entity holoEntity = null;
        for (Entity e : instance.getEntities()) {
            if ("shop".equals(HologramRuntime.holoNameForEntity(e.getEntityId()))) {
                holoEntity = e;
                break;
            }
        }
        if (holoEntity == null) {
            System.err.println("[INLINE] FAIL no hologram interaction entity found");
            failures++;
        } else {
            aliceWire.sent.clear();
            EventDispatcher.call(new PlayerEntityInteractEvent(alice, holoEntity,
                    PlayerHand.MAIN, holoEntity.getPosition()));
            failures += expect("hologram on_click ran with player bound", true,
                    aliceWire.saw("holo:Alice"));
        }

        System.out.println("[INLINE] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[INLINE] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }

    /** Records outbound packets so sent chat messages can be asserted. */
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

        boolean saw(String text) {
            for (SendablePacket packet : sent) {
                if (String.valueOf(packet).contains(text)) {
                    return true;
                }
            }
            return false;
        }

        boolean lowerSaw(String text) {
            String needle = text.toLowerCase();
            for (SendablePacket packet : sent) {
                if (String.valueOf(packet).toLowerCase().contains(needle)) {
                    return true;
                }
            }
            return false;
        }
    }
}
