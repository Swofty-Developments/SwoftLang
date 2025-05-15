package net.swofty.event.events;

import java.lang.reflect.Method;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.PlayerEvent;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.nativebridge.representation.Event;

public class GenericSwoftEvent extends AbstractSwoftEvent<net.minestom.server.event.Event> {
    public GenericSwoftEvent(net.minestom.server.event.Event minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

@Override
    public CommandSender getSender() {
        // Try to find a player associated with this event
        if (minestomEvent instanceof PlayerEvent) {
            try {
                // Use reflection to get the player
                Method getPlayerMethod = minestomEvent.getClass().getMethod("getPlayer");
                Object result = getPlayerMethod.invoke(minestomEvent);
                if (result instanceof Player) {
                    return (Player) result;
                }
            } catch (Exception e) {
                // Ignore reflection errors
            }
        }
        
        // Fallback to the console sender
        return MinecraftServer.getCommandManager().getConsoleSender();
    }
    
    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        // Add basic event information
        variables.put("eventClass", minestomEvent.getClass().getSimpleName());
        
        // Try to extract common properties via reflection
        extractPropertiesViaReflection(variables);
    }
    
    /**
     * Extract properties from the Minestom event via reflection
     */
    private void extractPropertiesViaReflection(Map<String, Object> variables) {
        // Try common getter methods
        tryGetterMethod(variables, "getPlayer", "player");
        tryGetterMethod(variables, "getMessage", "message");
        tryGetterMethod(variables, "getUsername", "username");
        tryGetterMethod(variables, "getName", "name");
        tryGetterMethod(variables, "getPosition", "position");
        tryGetterMethod(variables, "getEntity", "entity");
        tryGetterMethod(variables, "getBlock", "block");
        tryGetterMethod(variables, "getItem", "item");
    }
    
    /**
     * Try to call a getter method and add the result to the variables map
     */
    private void tryGetterMethod(Map<String, Object> variables, String methodName, String variableName) {
        try {
            Method method = minestomEvent.getClass().getMethod(methodName);
            Object result = method.invoke(minestomEvent);
            if (result != null) {
                variables.put(variableName, result);
            }
        } catch (Exception e) {
            // Ignore reflection errors - this just means the event doesn't have this property
        }
    }
}