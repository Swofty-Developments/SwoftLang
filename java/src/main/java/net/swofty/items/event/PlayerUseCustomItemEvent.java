package net.swofty.items.event;

import net.minestom.server.entity.Player;
import net.minestom.server.entity.PlayerHand;
import net.minestom.server.event.trait.CancellableEvent;
import net.minestom.server.event.trait.PlayerEvent;
import net.minestom.server.item.ItemStack;

/**
 * Fired (via EventDispatcher) whenever a player interacts (left or right
 * click) with a custom item - in ADDITION to ability execution (design 5A).
 * Cancelling also cancels the underlying Minestom interact event when it is
 * cancellable. Carries the originating hand so handler 'item' rebinds can
 * be flushed back to the correct slot.
 */
public class PlayerUseCustomItemEvent implements PlayerEvent, CancellableEvent {
    private final Player player;
    private final ItemStack item;
    private final String customId;
    private final String activation;
    private final PlayerHand hand;
    private boolean cancelled;

    public PlayerUseCustomItemEvent(Player player, ItemStack item, String customId,
            String activation, PlayerHand hand) {
        this.player = player;
        this.item = item;
        this.customId = customId;
        this.activation = activation;
        this.hand = hand;
    }

    @Override
    public Player getPlayer() {
        return player;
    }

    public ItemStack getItem() {
        return item;
    }

    public String getCustomId() {
        return customId;
    }

    /** "right_click" or "left_click". */
    public String getActivation() {
        return activation;
    }

    /** The hand the interact came from (write-back target for 'item'). */
    public PlayerHand getHand() {
        return hand;
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
