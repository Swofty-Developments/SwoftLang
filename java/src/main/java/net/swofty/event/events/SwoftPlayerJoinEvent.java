package net.swofty.event.events;

import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerSpawnEvent;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;

public class SwoftPlayerJoinEvent extends AbstractSwoftEvent<PlayerSpawnEvent> {
    public SwoftPlayerJoinEvent(PlayerSpawnEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("player", getPlayer());
        variables.put("name", getPlayer().getUsername());
    }
    
    
    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }
    
    public String getName() {
        return minestomEvent.getPlayer().getUsername();
    }
}