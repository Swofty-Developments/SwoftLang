package net.swofty.event.events;

import java.util.Map;

import net.kyori.adventure.text.Component;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.player.PlayerChatEvent;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;

public class SwoftPlayerChatEvent extends AbstractSwoftEvent<PlayerChatEvent> {
    private String message;

    public SwoftPlayerChatEvent(PlayerChatEvent minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
        this.message = minestomEvent.getRawMessage();
    }

    @Override
    public CommandSender getSender() {
        return minestomEvent.getPlayer();
    }
    
    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        variables.put("player", minestomEvent.getPlayer());
        variables.put("message", getMessage());
    }
    
    // Getters and setters that will be accessed via reflection
    
    public Player getPlayer() {
        return minestomEvent.getPlayer();
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
        minestomEvent.setFormattedMessage(Component.text(message));
    }
}