package net.swofty.fishing.event;

import net.minestom.server.coordinate.Pos;
import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.PlayerEvent;
import org.jetbrains.annotations.NotNull;

/**
 * Fired the moment a fish bites the player's bobber (phase 8): the dip,
 * splash and sound have played, and the catch window is open.
 */
public class FishBiteEvent implements PlayerEvent {
    private final Player player;
    private final Pos hookLocation;

    public FishBiteEvent(Player player, Pos hookLocation) {
        this.player = player;
        this.hookLocation = hookLocation;
    }

    @Override
    public @NotNull Player getPlayer() {
        return player;
    }

    public Pos getHookLocation() {
        return hookLocation;
    }
}
