package net.swofty.harness;

import java.net.InetSocketAddress;
import java.net.SocketAddress;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CopyOnWriteArrayList;

import net.kyori.adventure.text.Component;
import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.BlockVec;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.GameMode;
import net.minestom.server.entity.ItemEntity;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.entity.damage.Damage;
import net.minestom.server.event.entity.EntityAttackEvent;
import net.minestom.server.event.entity.EntityDamageEvent;
import net.minestom.server.event.inventory.InventoryPreClickEvent;
import net.minestom.server.event.item.PickupItemEvent;
import net.minestom.server.event.player.PlayerBlockInteractEvent;
import net.minestom.server.event.player.PlayerDeathEvent;
import net.minestom.server.event.player.PlayerGameModeChangeEvent;
import net.minestom.server.event.player.PlayerMoveEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.InstanceContainer;
import net.minestom.server.instance.block.Block;
import net.minestom.server.instance.block.BlockFace;
import net.minestom.server.inventory.Inventory;
import net.minestom.server.inventory.InventoryType;
import net.minestom.server.inventory.click.Click;
import net.minestom.server.item.ItemStack;
import net.minestom.server.item.Material;
import net.minestom.server.network.packet.server.SendablePacket;
import net.minestom.server.network.player.GameProfile;
import net.minestom.server.network.player.PlayerConnection;
import net.swofty.InstanceRegistry;
import net.swofty.event.events.GenericSwoftEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.PathResolver;
import net.swofty.props.PropertyTables;

/**
 * --wevents-probe: end-to-end proofs for the W-events typed engine catalog.
 * For ~8 representative events it builds the REAL Minestom event, wraps it in
 * the generic runtime wrapper scripts see (GenericSwoftEvent, driven by the
 * EventPropertyResolver typed rows), then reads the typed properties and
 * exercises the settable ones through the same script-facing path
 * (PathResolver.getProperty / setDynamicProperty), asserting the concrete
 * value each resolves to.
 */
public final class WEventsProbe {

    private WEventsProbe() {
    }

    public static int run() throws Exception {
        MinecraftServer.init();
        PropertyTables.ensureRegistered();
        InstanceContainer instance = MinecraftServer.getInstanceManager()
                .createInstanceContainer();
        InstanceRegistry.register("world", instance);

        int failures = 0;
        failures += entityDamage();
        failures += playerDeath(instance);
        failures += playerMove(instance);
        failures += inventoryPreClick(instance);
        failures += playerGameModeChange(instance);
        failures += entityAttack();
        failures += pickupItem();
        failures += playerBlockInteract(instance);

        System.out.println("[WEVENTS] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // EntityDamage: read damage/attacker, then set damage (Damage unwrap)
    // ------------------------------------------------------------------

    private static int entityDamage() {
        int failures = 0;
        LivingEntity victim = new LivingEntity(EntityType.ZOMBIE);
        Entity attacker = new Entity(EntityType.SKELETON);
        Damage damage = Damage.fromEntity(attacker, 5.0f);
        EntityDamageEvent raw = new EntityDamageEvent(victim, damage, null);
        GenericSwoftEvent ev = wrap(raw, "EntityDamage");

        failures += expect("EntityDamage.entity", victim, get(ev, "entity"));
        failures += expect("EntityDamage.damage read", 5.0, get(ev, "damage"));
        failures += expect("EntityDamage.attacker read", attacker, get(ev, "attacker"));
        // settable write through the Damage unwrap (setAmount)
        ev.setDynamicProperty("damage", 2.0, 0, 0);
        failures += expect("EntityDamage.damage after set (read back)", 2.0,
                get(ev, "damage"));
        failures += expect("EntityDamage.damage after set (engine getAmount)", 2.0f,
                raw.getDamage().getAmount());
        return report("EntityDamage", failures);
    }

    // ------------------------------------------------------------------
    // PlayerDeath: set death_text (Component <-> String bridge)
    // ------------------------------------------------------------------

    private static int playerDeath(Instance instance) {
        int failures = 0;
        Player player = fakePlayer("Slain");
        player.setInstance(instance, new Pos(0, 40, 0));
        PlayerDeathEvent raw = new PlayerDeathEvent(player,
                Component.text("orig-death"), Component.text("orig-chat"));
        GenericSwoftEvent ev = wrap(raw, "PlayerDeath");

        failures += expect("PlayerDeath.player", player, get(ev, "player"));
        ev.setDynamicProperty("death_text", "You died", 0, 0);
        failures += expect("PlayerDeath.death_text after set (read back)", "You died",
                get(ev, "death_text"));
        // engine truth: the Component setter took
        failures += expect("PlayerDeath.death_text (engine plain)", "You died",
                net.swofty.TextFormat.plain(raw.getDeathText()));
        return report("PlayerDeath", failures);
    }

    // ------------------------------------------------------------------
    // PlayerMove: read new_position (Pos -> Location)
    // ------------------------------------------------------------------

    private static int playerMove(Instance instance) {
        int failures = 0;
        Player player = fakePlayer("Walker");
        player.setInstance(instance, new Pos(0, 40, 0));
        Pos target = new Pos(3.5, 41, -2.5);
        PlayerMoveEvent raw = new PlayerMoveEvent(player, target, true);
        GenericSwoftEvent ev = wrap(raw, "PlayerMove");

        failures += expect("PlayerMove.new_position read", target, get(ev, "new_position"));
        failures += expect("PlayerMove.on_ground read", true, get(ev, "on_ground"));
        // bonus: new_position is settable
        Pos moved = new Pos(9, 42, 9);
        ev.setDynamicProperty("new_position", moved, 0, 0);
        failures += expect("PlayerMove.new_position after set", moved,
                get(ev, "new_position"));
        return report("PlayerMove", failures);
    }

    // ------------------------------------------------------------------
    // InventoryPreClick: read slot/clicked_item, then cancel
    // ------------------------------------------------------------------

    private static int inventoryPreClick(Instance instance) {
        int failures = 0;
        Player player = fakePlayer("Clicker");
        player.setInstance(instance, new Pos(0, 40, 0));
        Inventory inv = new Inventory(InventoryType.CHEST_3_ROW, "probe");
        ItemStack diamond = ItemStack.of(Material.DIAMOND, 7);
        inv.setItemStack(3, diamond);
        InventoryPreClickEvent raw = new InventoryPreClickEvent(inv, player,
                new Click.Left(3));
        GenericSwoftEvent ev = wrap(raw, "InventoryPreClick");

        failures += expect("InventoryPreClick.slot read", 3, get(ev, "slot"));
        failures += expect("InventoryPreClick.clicked_item read", diamond,
                get(ev, "clicked_item"));
        failures += expect("InventoryPreClick.cancelled default", false,
                get(ev, "cancelled"));
        ev.setDynamicProperty("cancelled", true, 0, 0);
        failures += expect("InventoryPreClick.cancelled after set", true,
                get(ev, "cancelled"));
        failures += expect("InventoryPreClick engine isCancelled", true, raw.isCancelled());
        return report("InventoryPreClick", failures);
    }

    // ------------------------------------------------------------------
    // PlayerGameModeChange: read new_game_mode (GameMode -> lowercase name)
    // ------------------------------------------------------------------

    private static int playerGameModeChange(Instance instance) {
        int failures = 0;
        Player player = fakePlayer("Changer");
        player.setInstance(instance, new Pos(0, 40, 0));
        PlayerGameModeChangeEvent raw = new PlayerGameModeChangeEvent(player,
                GameMode.CREATIVE);
        GenericSwoftEvent ev = wrap(raw, "PlayerGameModeChange");

        failures += expect("PlayerGameModeChange.new_game_mode read", "creative",
                get(ev, "new_game_mode"));
        // settable: enum coercion on write, lowercase name on read back
        ev.setDynamicProperty("new_game_mode", "survival", 0, 0);
        failures += expect("PlayerGameModeChange.new_game_mode after set", "survival",
                get(ev, "new_game_mode"));
        return report("PlayerGameModeChange", failures);
    }

    // ------------------------------------------------------------------
    // EntityAttack: read attacker (entity) + target
    // ------------------------------------------------------------------

    private static int entityAttack() {
        int failures = 0;
        Entity attacker = new Entity(EntityType.SKELETON);
        Entity target = new Entity(EntityType.ZOMBIE);
        EntityAttackEvent raw = new EntityAttackEvent(attacker, target);
        GenericSwoftEvent ev = wrap(raw, "EntityAttack");

        // the catalog names the attacker 'entity'; the target is 'target'
        failures += expect("EntityAttack.entity (attacker) read", attacker,
                get(ev, "entity"));
        failures += expect("EntityAttack.target read", target, get(ev, "target"));
        return report("EntityAttack", failures);
    }

    // ------------------------------------------------------------------
    // PickupItem: read item (item_stack) + entity
    // ------------------------------------------------------------------

    private static int pickupItem() {
        int failures = 0;
        LivingEntity picker = new LivingEntity(EntityType.ZOMBIE);
        ItemStack loot = ItemStack.of(Material.GOLD_INGOT, 4);
        ItemEntity dropped = new ItemEntity(loot);
        PickupItemEvent raw = new PickupItemEvent(picker, dropped);
        GenericSwoftEvent ev = wrap(raw, "PickupItem");

        failures += expect("PickupItem.item_stack read", loot, get(ev, "item_stack"));
        failures += expect("PickupItem.entity read", picker, get(ev, "entity"));
        failures += expect("PickupItem.item_entity read", dropped, get(ev, "item_entity"));
        return report("PickupItem", failures);
    }

    // ------------------------------------------------------------------
    // PlayerBlockInteract: read block (id) + block_face (enum -> name)
    // ------------------------------------------------------------------

    private static int playerBlockInteract(Instance instance) {
        int failures = 0;
        Player player = fakePlayer("Interactor");
        player.setInstance(instance, new Pos(0, 40, 0));
        PlayerBlockInteractEvent raw = new PlayerBlockInteractEvent(player,
                PlayerHand.MAIN, instance, Block.STONE, new BlockVec(1, 40, 1),
                new Pos(1.5, 40.5, 1.5), BlockFace.TOP);
        GenericSwoftEvent ev = wrap(raw, "PlayerBlockInteract");

        failures += expect("PlayerBlockInteract.block read", "minecraft:stone",
                get(ev, "block"));
        failures += expect("PlayerBlockInteract.block_face read", "top",
                get(ev, "block_face"));
        failures += expect("PlayerBlockInteract.hand read", "main", get(ev, "hand"));
        // 'location' friendly alias resolves off block_position (BlockVec -> Location)
        failures += expect("PlayerBlockInteract.location read", new Pos(1, 40, 1),
                get(ev, "location"));
        return report("PlayerBlockInteract", failures);
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private static GenericSwoftEvent wrap(net.minestom.server.event.Event raw, String name) {
        return new GenericSwoftEvent(raw, new Event(name));
    }

    private static Object get(GenericSwoftEvent ev, String prop) {
        return PathResolver.getProperty(ev, prop, 0, 0);
    }

    private static Player fakePlayer(String name) {
        return new Player(new FakeConnection(), new GameProfile(UUID.randomUUID(), name));
    }

    private static int report(String event, int failures) {
        System.out.println("[WEVENTS] " + event + ": "
                + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected == null ? actual == null : expected.equals(actual)) {
            return 0;
        }
        System.err.println("[WEVENTS] FAIL " + what + ": expected " + expected
                + " (" + typeOf(expected) + "), got " + actual + " (" + typeOf(actual) + ")");
        return 1;
    }

    private static String typeOf(Object o) {
        return o == null ? "null" : o.getClass().getSimpleName();
    }

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
