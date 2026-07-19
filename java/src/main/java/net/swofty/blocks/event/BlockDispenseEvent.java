package net.swofty.blocks.event;

import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.event.Event;
import net.minestom.server.event.trait.CancellableEvent;
import net.minestom.server.instance.Instance;
import net.minestom.server.instance.block.Block;
import net.minestom.server.item.ItemStack;

/**
 * Fired by {@link net.swofty.blocks.DispenserRuntime} just BEFORE a
 * dispenser/dropper pops an item (phase 9 §5). The item is read/write so a
 * handler can swap what comes out (or none while the block is empty); the
 * facing direction and block position are read-only; cancelling means
 * nothing moves and the slot is left untouched.
 */
public class BlockDispenseEvent implements Event, CancellableEvent {
    private final Instance instance;
    private final Point position;
    private final Block block;
    private ItemStack item;
    private final Vec direction;
    private boolean cancelled;

    public BlockDispenseEvent(Instance instance, Point position, Block block,
            ItemStack item, Vec direction) {
        this.instance = instance;
        this.position = position;
        this.block = block;
        this.item = item;
        this.direction = direction;
    }

    public Instance getInstance() {
        return instance;
    }

    public Point getPosition() {
        return position;
    }

    public Block getBlock() {
        return block;
    }

    public ItemStack getItem() {
        return item;
    }

    public void setItem(ItemStack item) {
        this.item = item;
    }

    public Vec getDirection() {
        return direction;
    }

    @Override
    public boolean isCancelled() {
        return cancelled;
    }

    @Override
    public void setCancelled(boolean cancelled) {
        this.cancelled = cancelled;
    }
}
