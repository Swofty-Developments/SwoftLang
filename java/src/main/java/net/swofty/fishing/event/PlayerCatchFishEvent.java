package net.swofty.fishing.event;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.CancellableEvent;
import net.minestom.server.event.trait.PlayerEvent;
import net.minestom.server.item.ItemStack;
import net.swofty.mobs.SwoftMob;
import org.jetbrains.annotations.NotNull;

/**
 * Fired when a reel-during-bite resolved a loot entry, BEFORE anything
 * is delivered (phase 8). Item catches expose the rolled stack
 * read-write (handlers can swap it); mob catches expose the constructed
 * mob read-only (it enters the world at the hook only after the event,
 * so cancelling discards it unspawned). Cancelling suppresses delivery;
 * the reel itself still happened.
 */
public class PlayerCatchFishEvent implements PlayerEvent, CancellableEvent {
    private final Player player;
    private final SwoftMob caughtMob;
    private final Pos hookLocation;
    private ItemStack caughtItem;
    private boolean cancelled;

    public PlayerCatchFishEvent(Player player, ItemStack caughtItem, SwoftMob caughtMob,
            Pos hookLocation) {
        this.player = player;
        this.caughtItem = caughtItem;
        this.caughtMob = caughtMob;
        this.hookLocation = hookLocation;
    }

    @Override
    public @NotNull Player getPlayer() {
        return player;
    }

    /** The rolled item stack, or null for mob catches. */
    public ItemStack getCaughtItem() {
        return caughtItem;
    }

    /** Swap the delivered item (item catches only). */
    public void setCaughtItem(ItemStack caughtItem) {
        this.caughtItem = caughtItem;
    }

    /** The rolled mob (not yet in the world), or null for item catches. */
    public SwoftMob getCaughtMob() {
        return caughtMob;
    }

    public Pos getHookLocation() {
        return hookLocation;
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
