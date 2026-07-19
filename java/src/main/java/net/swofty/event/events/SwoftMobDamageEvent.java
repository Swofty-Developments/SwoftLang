package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.mobs.SwoftMob;
import net.swofty.mobs.event.MobDamageEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.NoneValue;

/**
 * on MobDamage wrapper: mob, attacker (optional), damage (rw), cancelled
 * (rw). Fired before the damage applies; setting damage mutates the
 * pending amount, cancelling drops the hit.
 */
public class SwoftMobDamageEvent extends AbstractSwoftEvent<MobDamageEvent> {
    public SwoftMobDamageEvent(MobDamageEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getAttacker() instanceof Player player
                ? player
                : MinecraftServer.getCommandManager().getConsoleSender();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("mob", minestomEvent.getMob());
        variables.put("attacker", getAttacker());
        // bare 'damage' alias (registry.ml declares it): a READ snapshot of
        // the pending amount - writes must go through 'set event.damage'
        variables.put("damage", getDamage());
    }

    public SwoftMob getMob() {
        return minestomEvent.getMob();
    }

    public Object getAttacker() {
        return minestomEvent.getAttacker() != null
                ? minestomEvent.getAttacker() : NoneValue.INSTANCE;
    }

    public double getDamage() {
        return minestomEvent.getAmount();
    }

    public void setDamage(double damage) {
        minestomEvent.setAmount(damage);
    }
}
