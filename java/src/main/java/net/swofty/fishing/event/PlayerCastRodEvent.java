package net.swofty.fishing.event;

import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.CancellableEvent;
import net.minestom.server.event.trait.PlayerEvent;
import org.jetbrains.annotations.NotNull;

/**
 * Fired when a player uses a fishing rod to cast, BEFORE the bobber
 * spawns (phase 8). Cancelling suppresses the cast entirely.
 */
public class PlayerCastRodEvent implements PlayerEvent, CancellableEvent {
    private final Player player;
    private boolean cancelled;

    public PlayerCastRodEvent(Player player) {
        this.player = player;
    }

    @Override
    public @NotNull Player getPlayer() {
        return player;
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
