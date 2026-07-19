package net.swofty.event.events;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Point;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.coordinate.Vec;
import net.minestom.server.item.ItemStack;
import net.swofty.blocks.event.BlockDispenseEvent;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.NoneValue;

/**
 * on BlockDispense wrapper (phase 9 §5): location, block, item (optional,
 * read/write to swap what comes out), direction (facing vector), cancelled.
 * Backed by {@link BlockDispenseEvent}; the console is the sender since no
 * player is involved.
 */
public class SwoftBlockDispenseEvent extends AbstractSwoftEvent<BlockDispenseEvent> {
    public SwoftBlockDispenseEvent(BlockDispenseEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return net.minestom.server.MinecraftServer.getCommandManager().getConsoleSender();
    }

    public Pos getLocation() {
        Point position = minestomEvent.getPosition();
        return new Pos(position.x(), position.y(), position.z());
    }

    /** Block key, e.g. "minecraft:dispenser". */
    public String getBlock() {
        return minestomEvent.getBlock().name();
    }

    /** The stack about to come out, none while the block is empty. */
    public Object getItem() {
        ItemStack item = minestomEvent.getItem();
        return item != null && !item.isAir() ? item : NoneValue.INSTANCE;
    }

    /** Swap the dispensed stack (pre-pop rw); none leaves the block empty. */
    public void setItem(ItemStack item) {
        minestomEvent.setItem(item);
    }

    public Vec getDirection() {
        return minestomEvent.getDirection();
    }
}
