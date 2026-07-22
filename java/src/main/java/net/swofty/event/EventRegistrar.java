package net.swofty.event;

import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.MinecraftServer;
import net.minestom.server.event.EventListener;
import net.minestom.server.event.EventNode;
import net.swofty.event.events.GenericSwoftEvent;
import net.swofty.model.ReactiveFieldModel;
import net.swofty.model.StructDefModel;
import net.swofty.nativebridge.representation.Event;
import net.swofty.structs.InstanceReceiverRuntime;

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
        ReceiverDispatch.resetBases();
        InstanceReceiverRuntime.reset();
    }

    /**
     * Register the struct-instance receivers (§4): one listener per distinct
     * {@code (subjectType, method)} that any reactive field declares. Each
     * listener delegates to {@link InstanceReceiverRuntime#dispatch}, which runs
     * the live instances whose reactive field equals the event subject.
     *
     * <p>MUST be called AFTER {@link #registerEvent} has registered the global
     * receivers, so a struct-instance listener sharing an event node is appended
     * after the global receiver's — giving the design's global -&gt; custom -&gt;
     * struct-instance order for cumulative (non-short-circuiting) cancel.
     */
    public void registerStructReceivers(List<StructDefModel> structs) {
        boolean anyReactive = false;
        Set<String> seen = new HashSet<>();
        for (StructDefModel def : structs) {
            if (!def.hasReactiveFields()) {
                continue;
            }
            anyReactive = true;
            for (ReactiveFieldModel field : def.reactive()) {
                String subjectType = field.subject();
                if (subjectType == null) {
                    continue;
                }
                for (String method : field.handlers().keySet()) {
                    if (seen.add(subjectType + "#" + method)) {
                        registerStructReceiverListener(subjectType, method);
                    }
                }
            }
        }
        // arm the runtime + derive the initial liveness index from the loaded
        // persistent roots (empty until instances are dropped into a persistent)
        InstanceReceiverRuntime.arm(anyReactive);
        InstanceReceiverRuntime.rebuild();
    }

    /**
     * Attach one struct-instance listener for {@code (subjectType, method)}:
     * resolve the native event it dispatches on (the same one a global receiver
     * of that method would), then delegate delivery to the instance runtime.
     */
    private void registerStructReceiverListener(String subjectType, String method) {
        String eventName = ReceiverEventMap.eventFor(subjectType, method);
        if (eventName == null) {
            System.out.println("Struct-instance receiver " + subjectType + "." + method
                    + " has no native event (rides a content runtime) - skipping");
            return;
        }
        ReceiverBinding.Spec spec = ReceiverBinding.lookup(eventName, subjectType);
        String className = spec != null && spec.minestomClass() != null
                ? spec.minestomClass() : null;
        if (className == null && EventType.fromIdentifier(eventName) != null) {
            className = EventType.getMinestomClassName(eventName);
        }
        if (className == null) {
            EventCatalog.Entry entry = EventCatalog.resolve(eventName).orElse(null);
            if (entry != null) {
                className = entry.className();
            }
        }
        if (className == null) {
            System.err.println("Struct-instance receiver " + subjectType + "." + method
                    + " -> unknown event '" + eventName + "' - skipping");
            return;
        }
        registerListener(eventName, className,
                (minestomEvent) -> InstanceReceiverRuntime.dispatch(
                        subjectType, method, spec, minestomEvent));
    }

    public void registerEvent(Event event) {
        String eventName = event.getName();

        // OOP receiver method: bind `this` + positional params (design OOP event
        // model) instead of the flat sender/event/alias scheme. Fans out
        // naturally — one native event maps to several `events` entries, one per
        // receiver, each attaching its own listener to the shared event node.
        if (event.isReceiver()) {
            registerReceiverEvent(event);
            return;
        }

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

    /**
     * Register one base-receiver method: resolve the Minestom event class it
     * listens on, index its body for {@code default()}/{@code super} chaining,
     * and attach a listener that binds {@code this} + the positional params.
     * Only receivers a script actually declares get a listener.
     */
    private void registerReceiverEvent(Event event) {
        String eventName = event.getName();
        ReceiverBinding.Spec spec = ReceiverBinding.lookup(eventName, event.getReceiver());

        // index the base body so a more-specific custom decl can reach it
        if (spec != null) {
            ReceiverDispatch.registerBase(event.getReceiver(), spec.method(),
                    event.getExecuteBlock(), event.getParams(), event.getSelf());
        }

        String className = spec != null && spec.minestomClass() != null
                ? spec.minestomClass() : null;
        if (className == null && EventType.fromIdentifier(eventName) != null) {
            className = EventType.getMinestomClassName(eventName);
        }
        if (className == null) {
            EventCatalog.Entry entry = EventCatalog.resolve(eventName).orElse(null);
            if (entry != null) {
                className = entry.className();
            }
        }
        if (className == null) {
            // `<Receiver>.<method>` names ride the inline-handler / npc / hologram
            // runtimes and have no distinct catalog event — nothing to attach here.
            if (eventName.contains(".")) {
                System.out.println("Receiver method " + eventName
                        + " has no catalog event (handled by its content runtime)");
                return;
            }
            List<String> suggestions = EventCatalog.suggest(eventName, 3);
            System.err.println("Unknown receiver event: " + eventName
                    + (suggestions.isEmpty() ? ""
                            : " (did you mean: " + String.join(", ", suggestions) + "?)"));
            return;
        }
        registerListener(eventName, className,
                (minestomEvent) -> ReceiverDispatch.fire(event, spec, minestomEvent));
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
