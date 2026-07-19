package net.swofty.mobs.event;

import net.minestom.server.entity.Player;
import net.minestom.server.event.Event;
import net.swofty.mobs.SwoftMob;

/**
 * Fired via EventDispatcher when a scripted mob dies (before loot rolls).
 * Not cancellable; killer is null unless the last damage came from a
 * player.
 */
public class MobDeathEvent implements Event {
    private final SwoftMob mob;
    private final Player killer;

    public MobDeathEvent(SwoftMob mob, Player killer) {
        this.mob = mob;
        this.killer = killer;
    }

    public SwoftMob getMob() {
        return mob;
    }

    public Player getKiller() {
        return killer;
    }
}
