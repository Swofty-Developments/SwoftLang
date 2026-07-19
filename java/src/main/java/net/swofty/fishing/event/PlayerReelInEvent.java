package net.swofty.fishing.event;

import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.PlayerEvent;
import org.jetbrains.annotations.NotNull;

/**
 * Fired on EVERY reel-in (phase 8), whether or not anything was caught:
 * re-using the rod while a bobber is out always reels it back.
 */
public class PlayerReelInEvent implements PlayerEvent {
    private final Player player;

    public PlayerReelInEvent(Player player) {
        this.player = player;
    }

    @Override
    public @NotNull Player getPlayer() {
        return player;
    }
}
