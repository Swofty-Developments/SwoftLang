package net.swofty.mobs;

import net.minestom.server.MinecraftServer;
import net.minestom.server.entity.Player;
import net.minestom.server.event.entity.EntityAttackEvent;
import net.minestom.server.event.item.PickupItemEvent;
/**
 * Wires the two EntityAttackEvent directions (design 5B / mobs spec 1.4):
 * scripted mob hits a player through SwoftMob.tryAttack (cooldown-gated),
 * and a player's melee swing on a scripted mob applies a flat vanilla-ish
 * base hit. Items no longer carry damage/strength stats (phase 9), so
 * scripters scale melee via their own tag-driven systems if they want.
 * Also owns the PickupItemEvent listener that routes dropped stacks into
 * player inventories.
 */
public final class MobRuntime {
    private static boolean initialized = false;

    private MobRuntime() {
    }

    public static synchronized void init() {
        if (initialized) {
            return;
        }
        initialized = true;
        MinecraftServer.getGlobalEventHandler().addListener(EntityAttackEvent.class, event -> {
            if (event.getEntity() instanceof SwoftMob mob
                    && event.getTarget() instanceof Player player) {
                mob.tryAttack(player);
            } else if (event.getEntity() instanceof Player player
                    && event.getTarget() instanceof SwoftMob mob) {
                // routes through the mob's on_hit handler (mob + attacker
                // bound, cancellable) before the flat base melee hit lands
                mob.handleMeleeHit(player);
            }
        });
        // Minestom's default (uncancelled) PickupItemEvent behaviour sends
        // the collect animation and REMOVES the item entity without adding
        // the stack to any inventory - that is the application's job. Add
        // it here; cancel when the inventory is full so the drop survives.
        MinecraftServer.getGlobalEventHandler().addListener(PickupItemEvent.class, event -> {
            if (event.getLivingEntity() instanceof Player player
                    && !player.getInventory().addItemStack(event.getItemStack())) {
                event.setCancelled(true);
            }
        });
    }

    /** Flat vanilla-ish base melee hit (items carry no damage stats now). */
    public static double playerMeleeDamage(Player player) {
        return 1.0;
    }
}
