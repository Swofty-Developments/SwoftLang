package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.item.ItemStack;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.fishing.event.PlayerCatchFishEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.NoneValue;

/**
 * on PlayerCatchFish wrapper (phase 8): player, caught_item (optional,
 * read-write — writing swaps the delivered stack), caught_mob (optional
 * mob id, read-only), hook_location, cancelled. Fires pre-delivery.
 */
public class SwoftPlayerCatchFishEvent extends AbstractSwoftEvent<PlayerCatchFishEvent> {
    public SwoftPlayerCatchFishEvent(PlayerCatchFishEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("player", minestomEvent.getPlayer());
    }

    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }

    /** The rolled stack, none for mob catches. */
    public Object getCaughtItem() {
        ItemStack stack = minestomEvent.getCaughtItem();
        return stack != null ? stack : NoneValue.INSTANCE;
    }

    /** Swap the delivered stack (pre-delivery rw support). */
    public void setCaughtItem(ItemStack stack) {
        minestomEvent.setCaughtItem(stack);
    }

    /** The rolled mob (spawns at the hook post-event), none for item catches. */
    public Object getCaughtMob() {
        net.swofty.mobs.SwoftMob mob = minestomEvent.getCaughtMob();
        return mob != null ? mob : NoneValue.INSTANCE;
    }

    public Pos getHookLocation() {
        return minestomEvent.getHookLocation();
    }
}
