package net.swofty.event;

import net.minestom.server.event.player.PlayerChatEvent;
import net.minestom.server.event.player.PlayerSpawnEvent;
import net.swofty.event.events.SwoftPlayerChatEvent;
import net.swofty.event.events.SwoftPlayerJoinEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * Registry of event types and their associated wrapper classes
 */
public enum EventType {
    // Define event types with their identifiers and wrapper class factories
    PLAYER_CHAT("PlayerChat", (minestomEvent, swoftEvent) -> 
        new SwoftPlayerChatEvent((PlayerChatEvent) minestomEvent, swoftEvent)),
    
    PLAYER_JOIN("PlayerJoin", (minestomEvent, swoftEvent) -> 
        new SwoftPlayerJoinEvent((PlayerSpawnEvent) minestomEvent, swoftEvent)),
        
        ;
    
    // Add more event types as needed
    
    private final String identifier;
    private final EventWrapperFactory factory;
    
    /**
     * Map from identifier to matching Minestom class name
     */
    private static final java.util.Map<String, String> MINESTOM_CLASS_MAP = new java.util.HashMap<>();
    
    static {
        // Initialize the mapping from identifiers to Minestom class names
        MINESTOM_CLASS_MAP.put("PlayerChat", "net.minestom.server.event.player.PlayerChatEvent");
        MINESTOM_CLASS_MAP.put("PlayerJoin", "net.minestom.server.event.player.PlayerSpawnEvent");
        MINESTOM_CLASS_MAP.put("PlayerMove", "net.minestom.server.event.player.PlayerMoveEvent");
        // Add more mappings as needed
    }
    
    EventType(String identifier, EventWrapperFactory factory) {
        this.identifier = identifier;
        this.factory = factory;
    }
    
    public String getIdentifier() {
        return identifier;
    }
    
    public EventWrapperFactory getFactory() {
        return factory;
    }
    
    /**
     * Get the corresponding Minestom class name for an event identifier
     */
    public static String getMinestomClassName(String identifier) {
        return MINESTOM_CLASS_MAP.getOrDefault(identifier, 
            // Default fallback - try to infer based on identifier
            identifier.startsWith("Player") ? 
                "net.minestom.server.event.player." + identifier + "Event" :
                identifier.startsWith("Entity") ? 
                    "net.minestom.server.event.entity." + identifier + "Event" :
                    "net.minestom.server.event." + identifier + "Event");
    }
    
    /**
     * Find an event type by its identifier
     */
    public static EventType fromIdentifier(String identifier) {
        for (EventType type : values()) {
            if (type.getIdentifier().equals(identifier)) {
                return type;
            }
        }
        return null;
    }
    
    /**
     * Functional interface for event wrapper factories
     */
    @FunctionalInterface
    public interface EventWrapperFactory {
        AbstractSwoftEvent<?> create(net.minestom.server.event.Event minestomEvent, Event swoftEvent);
    }
}