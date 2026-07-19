package net.swofty.entities;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.EntityProjectile;
import net.minestom.server.entity.LivingEntity;
import net.minestom.server.entity.damage.Damage;
import net.minestom.server.event.entity.projectile.ProjectileCollideWithEntityEvent;

/**
 * Bridges projectile collisions into the damage pipeline (phase 7): the
 * pinned EntityProjectile fires ProjectileCollideWithEntityEvent but
 * applies no damage itself, so without this listener launched arrows and
 * snowballs would never hurt anything and no EntityDamage/MobDamage
 * handler would ever see shooter attribution. Damage.fromProjectile puts
 * the shooter in getAttacker(), so mob on_damage handlers and the
 * MobDamage wrapper both attribute the hit to the launching entity.
 */
public final class ProjectileRuntime {
    /** Base damage per block-per-tick of projectile speed (vanilla-arrow-ish). */
    private static final double DAMAGE_PER_SPEED = 2.0;
    private static final double TICKS_PER_SECOND = 20.0;

    private static boolean initialized = false;

    private ProjectileRuntime() {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        MinecraftServer.getGlobalEventHandler().addListener(
                ProjectileCollideWithEntityEvent.class, event -> {
                    if (event.isCancelled()
                            || !(event.getEntity() instanceof EntityProjectile projectile)
                            || !(event.getTarget() instanceof LivingEntity target)) {
                        return;
                    }
                    target.damage(Damage.fromProjectile(projectile.getShooter(),
                            projectile, (float) damageFor(projectile)));
                    // vanilla-style: the projectile is spent on an entity hit
                    projectile.remove();
                });
    }

    /** Speed-scaled damage, min 1.0: entity velocity is blocks/second. */
    private static double damageFor(EntityProjectile projectile) {
        double blocksPerTick = projectile.getVelocity().length() / TICKS_PER_SECOND;
        return Math.max(1.0, DAMAGE_PER_SPEED * blocksPerTick);
    }
}
