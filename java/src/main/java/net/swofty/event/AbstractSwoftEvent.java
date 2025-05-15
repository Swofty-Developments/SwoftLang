package net.swofty.event;

import java.util.HashMap;
import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.event.trait.CancellableEvent;
import net.swofty.ASTExecutor;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * Base class for event wrappers that adapts Minestom events to SwoftLang
 */
public abstract class AbstractSwoftEvent<T extends net.minestom.server.event.Event> {
    protected final T minestomEvent;
    protected final Event swoftEvent;
    protected boolean cancelled = false;

    public AbstractSwoftEvent(T minestomEvent, Event swoftEvent) {
        this.minestomEvent = minestomEvent;
        this.swoftEvent = swoftEvent;
    }

    /**
     * Execute the SwoftLang event code
     */
    public boolean execute() {
        ExecuteBlock executeBlock = swoftEvent.getExecuteBlock();
        if (executeBlock == null) {
            return false;
        }

        // Create the variables map for the executor
        Map<String, Object> variables = createVariablesMap();
        
        // Execute the code with the enhanced ASTExecutor
        ASTExecutor executor = new ASTExecutor(getSender(), variables);
        executor.execute(executeBlock);

        return cancelled;
    }

    /**
     * Create the variables map for the executor
     */
    protected Map<String, Object> createVariablesMap() {
        Map<String, Object> variables = new HashMap<>();
        
        // Add the event object itself
        variables.put("event", this);
        
        // Add sender
        variables.put("sender", getSender());
        
        // Add any custom variables
        addCustomVariables(variables);
        
        return variables;
    }
    
    /**
     * Add custom variables to the map
     * Override in subclasses to add event-specific variables
     */
    protected void addCustomVariables(Map<String, Object> variables) {
        // Default implementation does nothing
        // Subclasses can override to add custom variables
    }

    /**
     * Get the command sender for this event
     */
    public abstract CommandSender getSender();

    /**
     * Cancel the event
     */
    public void cancel() {
        this.cancelled = true;
        if (minestomEvent instanceof CancellableEvent) {
            ((CancellableEvent) minestomEvent).setCancelled(true);
        }
    }

    /**
     * Get the Minestom event
     */
    public T getMinestomEvent() {
        return minestomEvent;
    }
}