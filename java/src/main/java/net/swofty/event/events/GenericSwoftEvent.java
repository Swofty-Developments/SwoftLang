package net.swofty.event.events;

import java.util.Locale;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.CancellableEvent;
import net.minestom.server.event.trait.PlayerEvent;
import net.swofty.ScriptError;
import net.swofty.event.AbstractSwoftEvent;
import net.swofty.event.EventPropertyResolver;
import net.swofty.nativebridge.representation.Event;
import net.swofty.props.DynamicPropertyOwner;
import net.swofty.runtime.SystemSender;

/**
 * The generic wrapper for catalog events (phase 7): any concrete
 * Minestom event without a curated Swoft wrapper is delivered through
 * this class. Property access is dynamic — the generated catalog rows
 * are resolved per event class by the cached MethodHandle-based
 * EventPropertyResolver — and 'cancelled' routes through the wrapper so
 * `cancel event` and `set event.cancelled to ...` stay in sync with the
 * underlying CancellableEvent.
 */
public class GenericSwoftEvent extends AbstractSwoftEvent<net.minestom.server.event.Event>
        implements DynamicPropertyOwner {

    public GenericSwoftEvent(net.minestom.server.event.Event minestomEvent, Event swoftEvent) {
        super(minestomEvent, swoftEvent);
    }

    @Override
    public CommandSender getSender() {
        if (minestomEvent instanceof PlayerEvent playerEvent) {
            try {
                Player player = playerEvent.getPlayer();
                if (player != null) {
                    return player;
                }
            } catch (Throwable ignored) {
                // fall through to the console sender
            }
        }
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }

    @Override
    protected void addCustomVariables(Map<String, Object> variables) {
        // player shortcut for player-scoped events; everything else is
        // reached through event.<property> catalog access
        if (minestomEvent instanceof PlayerEvent playerEvent) {
            try {
                Player player = playerEvent.getPlayer();
                if (player != null) {
                    variables.put("player", player);
                }
            } catch (Throwable ignored) {
                // no player shortcut
            }
        }
    }

    /**
     * The underlying event is the source of truth for cancellation, so
     * a wrapper created around an already-cancelled event reads true.
     */
    @Override
    public boolean isCancelled() {
        if (minestomEvent instanceof CancellableEvent cancellable) {
            return cancellable.isCancelled();
        }
        return super.isCancelled();
    }

    // ------------------------------------------------------------------
    // dynamic catalog properties
    // ------------------------------------------------------------------

    @Override
    public boolean hasDynamicProperty(String name) {
        String key = name.toLowerCase(Locale.ROOT);
        if ("cancelled".equals(key)) {
            return true;
        }
        return handles().containsKey(key);
    }

    @Override
    public Object getDynamicProperty(String name, int line, int col) {
        String key = name.toLowerCase(Locale.ROOT);
        if ("cancelled".equals(key)) {
            return isCancelled();
        }
        EventPropertyResolver.Handle handle = handles().get(key);
        if (handle == null) {
            throw unknownProperty(name, line, col);
        }
        try {
            return EventPropertyResolver.read(minestomEvent, handle);
        } catch (ScriptError e) {
            throw e.at(line, col);
        }
    }

    @Override
    public void setDynamicProperty(String name, Object value, int line, int col) {
        String key = name.toLowerCase(Locale.ROOT);
        if ("cancelled".equals(key)) {
            if (!(minestomEvent instanceof CancellableEvent)) {
                throw new ScriptError("event " + eventDisplayName()
                        + " is not cancellable", line, col);
            }
            setCancelled((Boolean) net.swofty.props.Coercions.toBoolean(value));
            return;
        }
        EventPropertyResolver.Handle handle = handles().get(key);
        if (handle == null) {
            throw unknownProperty(name, line, col);
        }
        try {
            EventPropertyResolver.write(minestomEvent, handle, value);
        } catch (ScriptError e) {
            throw e.at(line, col);
        }
    }

    private Map<String, EventPropertyResolver.Handle> handles() {
        return EventPropertyResolver.handlesFor(minestomEvent.getClass());
    }

    private ScriptError unknownProperty(String name, int line, int col) {
        String available = String.join(", ",
                handles().keySet().stream().sorted().toList());
        return new ScriptError("unknown property '" + name + "' on event "
                + eventDisplayName()
                + (available.isEmpty() ? "" : " (available: " + available + ")"),
                line, col);
    }

    private String eventDisplayName() {
        return minestomEvent.getClass().getSimpleName();
    }
}
