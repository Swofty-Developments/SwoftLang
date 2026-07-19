package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.item.ItemStack;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.items.event.PlayerUseCustomItemEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.NoneValue;

/**
 * on PlayerUseItem wrapper: player, item, custom_id (optional), cancelled.
 */
public class SwoftPlayerUseItemEvent extends AbstractSwoftEvent<PlayerUseCustomItemEvent> {
    public SwoftPlayerUseItemEvent(PlayerUseCustomItemEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("player", minestomEvent.getPlayer());
        variables.put("item", minestomEvent.getItem());
    }

    /**
     * The bound 'item' is a bare ItemStack copy; if the handler rebound it
     * (e.g. 'set item.tags.x'), flush the new stack back to the hand slot
     * the interact came from (compare-and-set, sync handlers only).
     */
    @Override
    protected void afterExecute(Map<String, Object> variables) {
        net.swofty.items.ItemInteractRuntime.flushItemRebind(minestomEvent.getPlayer(),
                minestomEvent.getHand(), minestomEvent.getItem(), variables.get("item"));
    }

    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }

    public ItemStack getItem() {
        return minestomEvent.getItem();
    }

    public Object getCustomId() {
        String id = minestomEvent.getCustomId();
        return id != null ? id : NoneValue.INSTANCE;
    }

    public String getActivation() {
        return minestomEvent.getActivation();
    }
}
