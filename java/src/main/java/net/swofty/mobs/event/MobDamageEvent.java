package net.swofty.mobs.event;

import net.minestom.server.entity.Entity;
import net.minestom.server.event.Event;
import net.minestom.server.event.trait.CancellableEvent;
import net.swofty.mobs.SwoftMob;

/**
 * Fired via EventDispatcher before damage applies to a scripted mob.
 * The amount is mutable and cancel drops the hit entirely (hit-shield
 * semantics).
 */
public class MobDamageEvent implements Event, CancellableEvent {
    private final SwoftMob mob;
    private final Entity attacker;
    private double amount;
    private boolean cancelled;

    public MobDamageEvent(SwoftMob mob, Entity attacker, double amount) {
        this.mob = mob;
        this.attacker = attacker;
        this.amount = amount;
    }

    public SwoftMob getMob() {
        return mob;
    }

    public Entity getAttacker() {
        return attacker;
    }

    public double getAmount() {
        return amount;
    }

    public void setAmount(double amount) {
        this.amount = amount;
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
