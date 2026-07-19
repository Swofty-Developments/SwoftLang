package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.mobs.SwoftMob;
import net.swofty.mobs.event.MobDeathEvent;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.NoneValue;

/** on MobDeath wrapper: mob, killer (optional). Not cancellable. */
public class SwoftMobDeathEvent extends AbstractSwoftEvent<MobDeathEvent> {
    public SwoftMobDeathEvent(MobDeathEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getKiller() != null
                ? minestomEvent.getKiller()
                : MinecraftServer.getCommandManager().getConsoleSender();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("mob", minestomEvent.getMob());
        variables.put("killer", getKiller());
    }

    public SwoftMob getMob() {
        return minestomEvent.getMob();
    }

    public Object getKiller() {
        return minestomEvent.getKiller() != null
                ? minestomEvent.getKiller() : NoneValue.INSTANCE;
    }
}
