package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.mobs.SwoftMob;
import net.swofty.mobs.event.MobSpawnEvent;
import net.swofty.nativebridge.representation.Event;

/** on MobSpawn wrapper: mob (read-only). */
public class SwoftMobSpawnEvent extends AbstractSwoftEvent<MobSpawnEvent> {
    public SwoftMobSpawnEvent(MobSpawnEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return MinecraftServer.getCommandManager().getConsoleSender();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("mob", minestomEvent.getMob());
    }

    public SwoftMob getMob() {
        return minestomEvent.getMob();
    }
}
