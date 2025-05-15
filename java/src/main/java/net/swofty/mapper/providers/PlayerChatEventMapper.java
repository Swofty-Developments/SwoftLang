package net.swofty.mapper.providers;

import net.kyori.adventure.text.Component;
import net.minestom.server.event.player.PlayerChatEvent;
import net.swofty.mapper.PropertyMapper;
import net.swofty.mapper.PropertyMapperProvider;
import net.swofty.mapper.PropertyMapperRegistry;

/**
 * Property mapper for PlayerChatEvent
 * Handles Minestom API differences for chat messages
 */
public class PlayerChatEventMapper implements PropertyMapperProvider {
    
    @Override
    public void registerMappings() {
        // Register PlayerChatEvent property mappings
        PropertyMapper<PlayerChatEvent> mapper = new PropertyMapper<>(PlayerChatEvent.class);
        
        // Map 'message' property to appropriate methods
        mapper.registerProperty("message", 
            // Getter - map 'message' to getRawMessage
            PlayerChatEvent::getRawMessage,
            // Setter - map 'message' to setMessage
            (event, value) -> {
                try {
                    String stringValue = value != null ? value.toString() : "";
                    event.setFormattedMessage(Component.text(stringValue));
                } catch (Exception e) {
                    System.err.println("Error setting message: " + e.getMessage());
                }
            }
        );
        
        // Register the mapper
        PropertyMapperRegistry.registerMapper(mapper);
    }
}