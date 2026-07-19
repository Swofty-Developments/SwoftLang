package net.swofty.blocks;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.entity.Entity;
import net.minestom.server.entity.EntityProjectile;
import net.minestom.server.entity.EntityType;
import net.minestom.server.entity.ItemEntity;
import net.minestom.server.event.EventDispatcher;
import net.minestom.server.event.GlobalEventHandler;
import net.minestom.server.event.player.PlayerBlockBreakEvent;
import net.minestom.server.event.player.PlayerBlockInteractEvent;
import net.minestom.server.event.player.PlayerBlockPlaceEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.minestom.server.inventory.Inventory;
import net.minestom.server.inventory.InventoryType;
import net.minestom.server.item.ItemStack;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.blocks.event.BlockDispenseEvent;
import net.swofty.entities.ScriptEntityRegistry;

/**
 * Dispenser / dropper block-entity runtime (phase 9 §5). Dispenser and
 * dropper blocks get real 3x3 block-entity inventories keyed by
 * instance+position: right-click opens the inventory, breaking the block
 * drops its contents. A dispenser fires — pops one item round-robin and
 * launches or ejects it in the block's facing direction — under a scoped
 * power model: an adjacent lever/button toggled, a redstone block placed
 * next to it, or the script statement `dispense from &lt;location&gt;`. Each
 * fire raises the cancellable {@link BlockDispenseEvent} before the pop so
 * handlers can swap or block what comes out. Projectile items
 * (arrow/snowball/egg/ender_pearl) launch as projectiles; everything else
 * ejects as an item entity; droppers always eject. Inventories and spawned
 * entities are cleared on reload.
 */
public final class DispenserRuntime {
    /** Vanilla-ish dispenser launch/eject speed, blocks per tick. */
    private static final double PROJECTILE_SPEED = 1.1;
    private static final double EJECT_SPEED = 0.35;
    private static final double TICKS_PER_SECOND = 20.0;

    private static final Map<BlockKey, Inventory> INVENTORIES = new ConcurrentHashMap<>();
    private static final Map<BlockKey, Integer> NEXT_SLOT = new ConcurrentHashMap<>();
    private static boolean initialized = false;

    private DispenserRuntime() {
    }

    /** Identity of one block-entity: which instance and which position. */
    private record BlockKey(UUID instance, int x, int y, int z) {
        static BlockKey of(Instance instance, Point pos) {
            return new BlockKey(instance.getUuid(), pos.blockX(), pos.blockY(), pos.blockZ());
        }
    }

    /** What one dispense produced (harness/statement observability). */
    public record Dispensed(ItemStack item, Entity entity, Vec direction, boolean projectile) {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        GlobalEventHandler handler = MinecraftServer.getGlobalEventHandler();

        handler.addListener(PlayerBlockInteractEvent.class, event -> {
            Block block = event.getBlock();
            Instance instance = event.getPlayer().getInstance();
            if (instance == null) {
                return;
            }
            Point pos = event.getBlockPosition();
            if (isDispenserLike(block)) {
                // right-click opens the block-entity inventory
                event.getPlayer().openInventory(inventoryOf(instance, pos, block));
                event.setCancelled(true);
            } else if (isSwitch(block)) {
                // scoped power: a toggled lever/button fires adjacent blocks
                fireNeighbours(instance, pos);
            }
        });

        handler.addListener(PlayerBlockBreakEvent.class, event -> {
            Block block = event.getBlock();
            if (!isDispenserLike(block)) {
                return;
            }
            Instance instance = event.getInstance();
            Point pos = event.getBlockPosition();
            dropContents(instance, pos);
        });

        handler.addListener(PlayerBlockPlaceEvent.class, event -> {
            if (!"minecraft:redstone_block".equals(event.getBlock().name())) {
                return;
            }
            Instance instance = event.getInstance();
            fireNeighbours(instance, event.getBlockPosition());
        });
    }

    /** Reset all block-entity state and remove any spawned entities (reload). */
    public static synchronized void reset() {
        INVENTORIES.clear();
        NEXT_SLOT.clear();
    }

    /** The block-entity inventory for a dispenser/dropper (created on demand). */
    public static Inventory inventoryOf(Instance instance, Point pos, Block block) {
        return INVENTORIES.computeIfAbsent(BlockKey.of(instance, pos), key ->
                new Inventory(InventoryType.WINDOW_3X3,
                        isDropper(block) ? "Dropper" : "Dispenser"));
    }

    /**
     * `dispense from &lt;location&gt;`: fire the dispenser/dropper at a location.
     * Errors if the block there is not a dispenser or dropper.
     */
    public static Dispensed dispenseFrom(Instance instance, Point pos) {
        if (instance == null) {
            throw new ScriptError("dispense from: no world for that location");
        }
        Block block = instance.getBlock(pos);
        if (!isDispenserLike(block)) {
            throw new ScriptError("dispense from: the block at "
                    + pos.blockX() + "," + pos.blockY() + "," + pos.blockZ()
                    + " is not a dispenser or dropper (found " + block.name() + ")");
        }
        return dispense(instance, pos, block);
    }

    /** The core fire: pop one item round-robin, raise the event, act on it. */
    public static Dispensed dispense(Instance instance, Point pos, Block block) {
        BlockKey key = BlockKey.of(instance, pos);
        Inventory inventory = inventoryOf(instance, pos, block);
        Vec direction = facing(block);

        int size = inventory.getSize();
        int start = NEXT_SLOT.getOrDefault(key, 0) % size;
        int slot = -1;
        for (int i = 0; i < size; i++) {
            int candidate = (start + i) % size;
            ItemStack stack = inventory.getItemStack(candidate);
            if (stack != null && !stack.isAir()) {
                slot = candidate;
                break;
            }
        }
        ItemStack popped = slot >= 0 ? inventory.getItemStack(slot) : ItemStack.AIR;
        ItemStack single = popped.isAir() ? null : popped.withAmount(1);

        // BlockDispense fires BEFORE the pop: cancel = nothing moves, and the
        // handler may swap 'item' (including into/out of an empty block)
        BlockDispenseEvent event = new BlockDispenseEvent(instance, pos, block, single, direction);
        EventDispatcher.call(event);
        if (event.isCancelled()) {
            return null;
        }
        ItemStack out = event.getItem();
        if (out == null || out.isAir()) {
            return null;
        }

        // consume one from the popped slot (a pure swap into an empty block
        // has no slot to spend)
        if (slot >= 0) {
            int remaining = popped.amount() - 1;
            inventory.setItemStack(slot, remaining <= 0 ? ItemStack.AIR : popped.withAmount(remaining));
            NEXT_SLOT.put(key, slot + 1);
        }

        ItemStack dispensed = out.withAmount(1);
        boolean dropper = isDropper(block);
        Entity entity;
        boolean projectile = !dropper && projectileType(dispensed.material()) != null;
        if (projectile) {
            entity = launchProjectile(instance, pos, dispensed, direction);
        } else {
            entity = ejectItem(instance, pos, dispensed, direction);
        }
        return new Dispensed(dispensed, entity, direction, projectile);
    }

    private static Entity launchProjectile(Instance instance, Point pos, ItemStack stack,
            Vec direction) {
        EntityType type = projectileType(stack.material());
        Pos spawn = spawnPos(pos, direction);
        Vec velocity = direction.normalize().mul(PROJECTILE_SPEED * TICKS_PER_SECOND);
        EntityProjectile projectile = new EntityProjectile(null, type);
        TickDispatch.call(() -> {
            projectile.setInstance(instance, spawn);
            projectile.setVelocity(velocity);
            ScriptEntityRegistry.track(projectile);
            return null;
        });
        return projectile;
    }

    private static Entity ejectItem(Instance instance, Point pos, ItemStack stack,
            Vec direction) {
        Pos spawn = spawnPos(pos, direction);
        Vec velocity = direction.normalize().mul(EJECT_SPEED * TICKS_PER_SECOND);
        ItemEntity item = new ItemEntity(stack);
        item.setPickupDelay(java.time.Duration.ofSeconds(1));
        TickDispatch.call(() -> {
            item.setInstance(instance, spawn);
            item.setVelocity(velocity);
            ScriptEntityRegistry.track(item);
            return null;
        });
        return item;
    }

    /** Centre of the block, nudged one step toward the facing direction. */
    private static Pos spawnPos(Point pos, Vec direction) {
        return new Pos(pos.blockX() + 0.5 + direction.x() * 0.7,
                pos.blockY() + 0.5 + direction.y() * 0.7,
                pos.blockZ() + 0.5 + direction.z() * 0.7);
    }

    /** Drop every stack in the block-entity inventory, then forget it. */
    private static void dropContents(Instance instance, Point pos) {
        BlockKey key = BlockKey.of(instance, pos);
        Inventory inventory = INVENTORIES.remove(key);
        NEXT_SLOT.remove(key);
        if (inventory == null || instance == null) {
            return;
        }
        Pos drop = new Pos(pos.blockX() + 0.5, pos.blockY() + 0.5, pos.blockZ() + 0.5);
        for (ItemStack stack : inventory.getItemStacks()) {
            if (stack != null && !stack.isAir()) {
                ItemEntity item = new ItemEntity(stack);
                item.setPickupDelay(java.time.Duration.ofSeconds(1));
                final Pos spawn = drop;
                TickDispatch.call(() -> {
                    item.setInstance(instance, spawn);
                    ScriptEntityRegistry.track(item);
                    return null;
                });
            }
        }
    }

    /** Fire any dispenser/dropper directly adjacent to a position. */
    private static void fireNeighbours(Instance instance, Point pos) {
        if (instance == null) {
            return;
        }
        int[][] offsets = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}};
        for (int[] offset : offsets) {
            Point neighbour = pos.add(offset[0], offset[1], offset[2]);
            Block block = instance.getBlock(neighbour);
            if (isDispenserLike(block)) {
                dispense(instance, neighbour, block);
            }
        }
    }

    /** The unit facing vector from the block's "facing" property. */
    public static Vec facing(Block block) {
        String facing = block.getProperty("facing");
        if (facing == null) {
            facing = "up";
        }
        return switch (facing) {
            case "north" -> new Vec(0, 0, -1);
            case "south" -> new Vec(0, 0, 1);
            case "west" -> new Vec(-1, 0, 0);
            case "east" -> new Vec(1, 0, 0);
            case "down" -> new Vec(0, -1, 0);
            default -> new Vec(0, 1, 0);
        };
    }

    private static EntityType projectileType(net.minestom.server.item.Material material) {
        String name = material.name();
        return switch (name) {
            case "minecraft:arrow" -> EntityType.ARROW;
            case "minecraft:snowball" -> EntityType.SNOWBALL;
            case "minecraft:egg" -> EntityType.EGG;
            case "minecraft:ender_pearl" -> EntityType.ENDER_PEARL;
            default -> null;
        };
    }

    public static boolean isDispenserLike(Block block) {
        String name = block.name();
        return "minecraft:dispenser".equals(name) || "minecraft:dropper".equals(name);
    }

    private static boolean isDropper(Block block) {
        return "minecraft:dropper".equals(block.name());
    }

    private static boolean isSwitch(Block block) {
        String name = block.name();
        return "minecraft:lever".equals(name) || name.endsWith("_button");
    }
}
