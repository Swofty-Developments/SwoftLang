package net.swofty.event;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.event.EventListener;
import net.minestom.server.event.EventNode;
import net.swofty.event.events.GenericSwoftEvent;
import net.swofty.nativebridge.representation.Event;

/**
 * Registers script event handlers against the global event handler.
 * Curated wrappers keep precedence for their event types (EventType);
 * every other name resolves through the generated Minestom catalog and
 * is delivered via the GenericSwoftEvent wrapper (phase 7).
 */
public class EventRegistrar {
    private EventNode<net.minestom.server.event.Event> rootNode;
    private final Map<String, EventNode<net.minestom.server.event.Event>> eventNodes =
            new ConcurrentHashMap<>();

    public EventRegistrar() {
        // The global event handler is resolved lazily (registerEvent runs after
        // MinecraftServer.init): minestom 26.2 leaves MinecraftServer.serverProcess
        // null until init(), so grabbing it in the constructor — which runs during
        // engine construction, before Bootstrap calls init() — would NPE.
    }

    private EventNode<net.minestom.server.event.Event> rootNode() {
        if (rootNode == null) {
            rootNode = MinecraftServer.getGlobalEventHandler();
        }
        return rootNode;
    }

    /**
     * Detach every script event listener from the global handler and forget
     * the child nodes, so a hot reload can re-register from a clean slate
     * without piling duplicate listeners onto the same node. Tick-safe: call
     * on the tick thread as part of an engine reload.
     */
    public void reset() {
        for (EventNode<net.minestom.server.event.Event> node : eventNodes.values()) {
            try {
                rootNode().removeChild(node);
            } catch (RuntimeException ignored) {
            }
        }
        eventNodes.clear();
    }

    public void registerEvent(Event event) {
        String eventName = event.getName();

        // curated wrappers first: typed rows + bespoke behavior win over
        // the generic catalog path for the events they cover
        EventType curated = EventType.fromIdentifier(eventName);
        if (curated != null) {
            registerListener(eventName, EventType.getMinestomClassName(eventName),
                    (minestomEvent) -> curated.getFactory().create(minestomEvent, event)
                            .execute());
            return;
        }

        // generic catalog path: short name, short name + "Event", or the
        // fully qualified class name of any generated event entry
        EventCatalog.Entry entry = EventCatalog.resolve(eventName).orElse(null);
        if (entry == null) {
            if (EventCatalog.entries().isEmpty()) {
                // a misdeployed server (no /events.json on the classpath and
                // no catalog on disk) must fail loudly, not silently drop
                // every generic handler
                throw new IllegalStateException("event catalog unavailable: cannot "
                        + "register 'event " + eventName + "' — the deployment is "
                        + "missing /events.json (see the EventCatalog warning above)");
            }
            List<String> suggestions = EventCatalog.suggest(eventName, 3);
            System.err.println("Unknown event type: " + eventName
                    + (suggestions.isEmpty() ? ""
                            : " (did you mean: " + String.join(", ", suggestions) + "?)"));
            return;
        }
        registerListener(eventName, entry.className(),
                (minestomEvent) -> new GenericSwoftEvent(minestomEvent, event).execute());
    }

    private interface WrapperInvoker {
        void deliver(net.minestom.server.event.Event minestomEvent);
    }

    @SuppressWarnings("unchecked")
    private void registerListener(String eventName, String className, WrapperInvoker invoker) {
        Class<net.minestom.server.event.Event> eventClass;
        try {
            Class<?> loaded = Class.forName(className);
            if (!net.minestom.server.event.Event.class.isAssignableFrom(loaded)) {
                System.err.println("Event class is not a Minestom event: " + className);
                return;
            }
            eventClass = (Class<net.minestom.server.event.Event>) loaded;
        } catch (ClassNotFoundException e) {
            System.err.println("Could not find Minestom event class: " + className);
            return;
        }

        // warm the generated property table so binding problems surface
        // at registration time instead of first delivery
        EventPropertyResolver.handlesFor(eventClass);

        EventNode<net.minestom.server.event.Event> node = eventNodes.computeIfAbsent(
                eventName, name -> {
                    EventNode<net.minestom.server.event.Event> child =
                            EventNode.all("swoftlang-" + name);
                    rootNode().addChild(child);
                    return child;
                });
        node.addListener(EventListener.of(eventClass, invoker::deliver));
        System.out.println("Registered listener for event: " + eventName
                + " -> " + className);
    }
}
