package net.swofty.mobs.event;

import net.minestom.server.event.Event;
import net.swofty.mobs.SwoftMob;

/**
 * Fired via EventDispatcher when a scripted mob spawns into an instance.
 */
public class MobSpawnEvent implements Event {
    private final SwoftMob mob;

    public MobSpawnEvent(SwoftMob mob) {
        this.mob = mob;
    }

    public SwoftMob getMob() {
        return mob;
    }
}
