package net.swofty.event;

import java.util.HashMap;
import java.util.Map;

import net.minestom.server.command.CommandSender;
import net.minestom.server.event.trait.CancellableEvent;
import net.swofty.ASTExecutor;
import net.swofty.async.AsyncRuntime;
import net.swofty.nativebridge.representation.Event;
import net.swofty.nativebridge.representation.ExecuteBlock;

/**
 * Base class for event wrappers that adapts Minestom events to SwoftLang
 */
public abstract class AbstractSwoftEvent<T extends net.minestom.server.event.Event> {
    protected final T minestomEvent;
    protected final Event swoftEvent;
    protected boolean cancelled = false;

    /**
     * A0.4 past/future value snapshots for value-changing events. Populated by
     * {@link #snapshotPast} before the handler runs; {@link #pastValue} reads a
     * pre-handler value so a handler can compare it against the mutated value.
     * Empty until a value-changing wrapper opts in.
     */
    protected Map<String, Object> pastValues = Map.of();

    public AbstractSwoftEvent(T minestomEvent, Event swoftEvent) {
        this.minestomEvent = minestomEvent;
        this.swoftEvent = swoftEvent;
    }

    /** Snapshot the current values of the named properties (before the handler). */
    protected void snapshotPast(String... names) {
        if (names.length == 0) {
            return;
        }
        pastValues = EventPropertyResolver.snapshot(minestomEvent, java.util.List.of(names));
    }

    /** The pre-handler ('past') value of a snapshotted property, or none. */
    public Object pastValue(String name) {
        return pastValues.getOrDefault(name.toLowerCase(java.util.Locale.ROOT),
                net.swofty.props.NoneValue.INSTANCE);
    }

    /**
     * Execute the SwoftLang event code. Async handlers detach onto a
     * virtual thread and the event proceeds uncancelled; sync handlers run
     * inline on the calling (tick) thread.
     */
    public boolean execute() {
        ExecuteBlock executeBlock = swoftEvent.getExecuteBlock();
        if (executeBlock == null) {
            return false;
        }

        Map<String, Object> variables = createVariablesMap();
        if (executeBlock.isAsync()) {
            AsyncRuntime.start("event " + swoftEvent.getName(),
                    () -> new ASTExecutor(getSender(), variables).execute(executeBlock));
            return cancelled;
        }

        new ASTExecutor(getSender(), variables).execute(executeBlock);
        afterExecute(variables);
        return cancelled;
    }

    /**
     * Hook called after a SYNC handler ran, with the (possibly mutated)
     * variables map. Wrappers that bind copy-valued variables (e.g. the
     * 'item' ItemStack) override this to flush rebinds back to their
     * origin. Async handlers detach and never flush.
     */
    protected void afterExecute(Map<String, Object> variables) {
        // default: nothing to write back
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
        setCancelled(true);
    }

    public boolean isCancelled() {
        return cancelled;
    }

    public void setCancelled(boolean cancelled) {
        this.cancelled = cancelled;
        if (minestomEvent instanceof CancellableEvent) {
            ((CancellableEvent) minestomEvent).setCancelled(cancelled);
        }
    }

    /**
     * Get the Minestom event
     */
    public T getMinestomEvent() {
        return minestomEvent;
    }
}