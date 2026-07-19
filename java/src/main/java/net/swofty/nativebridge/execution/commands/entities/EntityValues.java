package net.swofty.nativebridge.execution.commands.entities;

import net.minestom.server.entity.Entity;
import net.minestom.server.entity.Player;
import net.minestom.server.instance.Instance;
import net.swofty.InstanceRegistry;
import net.swofty.ScriptError;
import net.swofty.displays.SwoftDisplay;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.Values;

/**
 * Shared coercions for the phase-7 entity statements. Mobs are entities
 * already (SwoftMob IS an EntityCreature); display values unwrap to
 * their backing display entity so `mount`/`dismount` treat them
 * uniformly.
 */
public final class EntityValues {

    private EntityValues() {
    }

    /**
     * Reject self-mounts and passenger cycles before addPassenger:
     * Minestom's addPassenger/updatePassengerPosition recursion never
     * terminates on a cycle (StackOverflowError on the tick thread) and
     * its own guard only rejects the direct two-entity case, with a raw
     * IllegalStateException. Walks the vehicle chain upward from the
     * intended vehicle; MUST run inside the same TickDispatch block as
     * the addPassenger call so the chain cannot change in between.
     */
    public static void checkMountCycle(Entity rider, Entity vehicle, String what) {
        if (rider == vehicle) {
            throw new ScriptError(what + ": cannot mount an entity on itself");
        }
        for (Entity link = vehicle.getVehicle(); link != null; link = link.getVehicle()) {
            if (link == rider) {
                throw new ScriptError(what
                        + ": mounting would create a mount cycle (the vehicle already "
                        + "rides on the entity being mounted)");
            }
        }
    }

    /** Any script value that IS or WRAPS a Minestom entity. */
    static Entity asEntity(Object value, String what) {
        if (value instanceof Entity entity) {
            return entity;
        }
        if (value instanceof SwoftDisplay display) {
            return display.entity();
        }
        throw new ScriptError(what + " expects an entity, got: "
                + Values.displayString(value));
    }

    /** The spawner's world when available, else the default overworld. */
    static Instance spawnInstance(ExecutionContext context, String what) {
        Instance instance = context.getSender() instanceof Player player
                && player.getInstance() != null
                ? player.getInstance()
                : InstanceRegistry.get("world");
        if (instance == null) {
            throw new ScriptError(what + ": no world to spawn into");
        }
        return instance;
    }
}
