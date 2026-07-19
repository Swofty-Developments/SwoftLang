package net.swofty.entities;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.entity.Entity;
import net.swofty.async.TickDispatch;

/**
 * Live plain entities and projectiles spawned by scripts (phase 7), so
 * reloads/shutdowns can clean up every script-owned entity in one sweep
 * — the counterpart of DisplayRegistry for displays and MobRegistry's
 * live list for mobs. Entities removed by other means are pruned lazily.
 */
public final class ScriptEntityRegistry {
    private static final Set<Entity> LIVE = ConcurrentHashMap.newKeySet();

    private ScriptEntityRegistry() {
    }

    public static void track(Entity entity) {
        LIVE.add(entity);
    }

    public static void untrack(Entity entity) {
        LIVE.remove(entity);
    }

    /** Live script-spawned entities still in a world. */
    public static int count() {
        LIVE.removeIf(Entity::isRemoved);
        return LIVE.size();
    }

    /** Remove every script-spawned entity from its world (reload/shutdown). */
    public static void removeAll() {
        for (Entity entity : Set.copyOf(LIVE)) {
            LIVE.remove(entity);
            if (!entity.isRemoved()) {
                TickDispatch.call(() -> {
                    entity.remove();
                    return null;
                });
            }
        }
    }
}
