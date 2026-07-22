package net.swofty.structs;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.IdentityHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import net.minestom.server.MinecraftServer;
import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.minestom.server.event.trait.PlayerEvent;
import net.minestom.server.item.ItemStack;
import net.swofty.ASTExecutor;
import net.swofty.event.EventPropertyResolver;
import net.swofty.event.EventPropertyResolver.Handle;
import net.swofty.event.ReceiverBinding;
import net.swofty.event.ReceiverBinding.Arg;
import net.swofty.event.ReceiverBinding.Spec;
import net.swofty.event.events.GenericSwoftEvent;
import net.swofty.items.ItemRegistry;
import net.swofty.mobs.SwoftMob;
import net.swofty.model.InlineHandler;
import net.swofty.model.ReactiveFieldModel;
import net.swofty.model.StructDefModel;
import net.swofty.nativebridge.representation.Event;
import net.swofty.persist.PersistStore;
import net.swofty.props.NoneValue;
import net.swofty.runtime.MapValue;
import net.swofty.runtime.SystemSender;

/**
 * Instance-receiver dispatch (§4): the runtime half of reactive struct fields.
 *
 * <p><b>Liveness (§4.2)</b> — a reactive struct instance's handlers fire iff the
 * instance is reachable from a persistent root. This runtime derives a
 * {@code (subjectType, method) -> live bindings} index by walking every value in
 * the {@link PersistStore} cache (persistent roots) and, for each reactive struct
 * instance found, registering a binding keyed by the value each {@code
 * @EventReceiver} field holds. Persistence holds the strong refs; removal from
 * persistent (a re-walk that no longer reaches the instance) is the teardown.
 * The index is rebuilt on load and on every persistent write (§4.2's
 * "walk on load and on write/flush"). RESOLVE-OR-CULL: an instance whose subject
 * field is {@code none}/unresolved is skipped (PersistStore already culls whole
 * struct rows whose Player subject can't re-resolve on load).
 *
 * <p><b>Dispatch (§4.3)</b> — {@link net.swofty.event.EventRegistrar} attaches one
 * listener per {@code (subjectType, method)} a reactive field declares. When it
 * fires, the global receiver and any custom override have already run (listeners
 * registered before these); this runtime then runs the instance handler of every
 * live instance whose reactive field equals the event subject. Cancel is
 * cumulative — all layers run, any may cancel, no short-circuit.
 *
 * <p><b>Backstop (§4.4)</b> — if the subject is custom-specialized (a custom mob
 * or custom item), the struct-instance handlers are skipped for it: a custom type
 * owns its behavior in its own block.
 */
public final class InstanceReceiverRuntime {

    /**
     * One live reactive binding: a struct instance + one of its reactive fields,
     * plus the persistent root (var, key) the instance was reached from. The root
     * lets a handler mutation to the instance re-dirty exactly the owning row so
     * the change is durable (§4.2), not just an in-memory edit lost on flush.
     */
    private record Binding(StructValue instance, ReactiveFieldModel field,
            String rootVar, String rootKey) {
    }

    // (subjectType + "#" + method) -> the live bindings that react to it.
    private static volatile Map<String, List<Binding>> index = Map.of();

    // Cheap gate: true once any registered struct declares a reactive field, so
    // a persist_set on a scalar-only script never walks the cache.
    private static volatile boolean armed = false;

    private InstanceReceiverRuntime() {
    }

    /**
     * Arm/disarm the runtime from the current struct declarations (called at
     * registration). Armed iff some struct has a reactive field; when disarmed
     * the index is dropped and every rebuild is a no-op.
     */
    public static void arm(boolean anyReactive) {
        armed = anyReactive;
        if (!anyReactive) {
            index = Map.of();
        }
    }

    /** Forget every live binding (hot reload / shutdown). */
    public static void reset() {
        armed = false;
        index = Map.of();
    }

    /**
     * Rebuild the liveness index from the persistent roots (§4.2). Cheap no-op
     * when disarmed. Called on load, on registration, and after every persistent
     * write so a struct dropped into (or removed from) a persistent goes live (or
     * dark) immediately.
     */
    public static synchronized void rebuild() {
        if (!armed) {
            index = Map.of();
            return;
        }
        Map<String, List<Binding>> next = new HashMap<>();
        PersistStore store = PersistStore.active();
        if (store != null) {
            IdentityHashMap<StructValue, Boolean> seen = new IdentityHashMap<>();
            store.forEachCachedRow((var, key, value) -> walk(var, key, value, seen, next));
        }
        index = next;
    }

    /**
     * Recursively register reactive instances reachable from a persistent value.
     * {@code rootVar}/{@code rootKey} identify the persistent row this value came
     * from (unchanged through the recursion), so a live binding remembers which
     * row to re-dirty when a handler mutates its instance (§4.2 durability).
     */
    private static void walk(String rootVar, String rootKey, Object value,
            IdentityHashMap<StructValue, Boolean> seen, Map<String, List<Binding>> out) {
        if (value instanceof StructValue struct) {
            if (seen.put(struct, Boolean.TRUE) != null) {
                return; // already visited (aliased / cyclic)
            }
            StructDefModel def = StructRegistry.get(struct.typeName());
            if (def != null && def.hasReactiveFields()) {
                for (ReactiveFieldModel field : def.reactive()) {
                    Object subject = struct.getField(field.field());
                    // RESOLVE-OR-CULL (§4.2/§4.4): a none/unresolved subject can't
                    // be dispatched to, so this field contributes no binding.
                    if (subject == null || NoneValue.isNone(subject)) {
                        continue;
                    }
                    Binding binding = new Binding(struct, field, rootVar, rootKey);
                    for (String method : field.handlers().keySet()) {
                        out.computeIfAbsent(field.subject() + "#" + method,
                                k -> new ArrayList<>()).add(binding);
                    }
                }
            }
            for (Object nested : struct.fields().values()) {
                walk(rootVar, rootKey, nested, seen, out);
            }
        } else if (value instanceof List<?> list) {
            for (Object element : new ArrayList<>(list)) {
                walk(rootVar, rootKey, element, seen, out);
            }
        } else if (value instanceof MapValue map) {
            for (Object element : map.snapshot().values()) {
                walk(rootVar, rootKey, element, seen, out);
            }
        }
    }

    // ------------------------------------------------------------------
    // dispatch
    // ------------------------------------------------------------------

    /**
     * Run the struct-instance handlers for one native event (§4.3), the last
     * layer after the global receiver and custom override. Resolves the subject
     * the same way the global receiver would (via {@code spec}, or the generic
     * player fallback), then runs each live instance whose reactive field equals
     * that subject.
     */
    public static void dispatch(String subjectType, String method, Spec spec,
            net.minestom.server.event.Event minestomEvent) {
        List<Binding> bindings = index.get(subjectType + "#" + method);
        if (bindings == null || bindings.isEmpty()) {
            return;
        }
        Map<String, Handle> handles = EventPropertyResolver.handlesFor(minestomEvent.getClass());
        Object subject = spec != null
                ? spec.subject().read(minestomEvent, handles)
                : genericSubject(minestomEvent);
        if (subject == null || NoneValue.isNone(subject)) {
            return;
        }
        // BACKSTOP (§4.4): a custom-specialized subject owns its behavior in its
        // own block; struct-instance handlers must not also drive it.
        if (isCustomSpecialized(subject)) {
            return;
        }
        // snapshot: a handler body may persist_set and trigger a rebuild, which
        // swaps the index; iterate a stable copy of this event's bindings.
        for (Binding binding : new ArrayList<>(bindings)) {
            InlineHandler handler = binding.field().handlers().get(method);
            if (handler == null) {
                continue;
            }
            Object fieldValue = binding.instance().getField(binding.field().field());
            if (!subjectMatches(fieldValue, subject)) {
                continue;
            }
            runHandler(binding, handler, method, spec, subject, minestomEvent, handles);
        }
    }

    /** Bind the struct's fields + the event's vars and run one instance handler. */
    private static void runHandler(Binding binding, InlineHandler handler, String method,
            Spec spec, Object subject, net.minestom.server.event.Event minestomEvent,
            Map<String, Handle> handles) {
        Map<String, Object> vars = new HashMap<>();
        // FULL struct context as bare vars (§4.1): every field, including the
        // reactive field itself (which IS the subject).
        for (Map.Entry<String, Object> entry : binding.instance().fields().entrySet()) {
            Object value = entry.getValue();
            vars.put(entry.getKey(), value == null ? NoneValue.INSTANCE : value);
        }

        // event args bind positionally to the handler's declared params.
        List<String> params = handler.params();
        List<Arg> argSpecs = spec != null ? spec.args() : null;
        for (int i = 0; i < params.size(); i++) {
            Object value;
            if (argSpecs != null) {
                value = i < argSpecs.size()
                        ? argSpecs.get(i).reader().read(minestomEvent, handles)
                        : NoneValue.INSTANCE;
            } else {
                value = readProp(minestomEvent, handles, params.get(i));
            }
            vars.put(params.get(i), value == null ? NoneValue.INSTANCE : value);
        }

        // the event wrapper lets a cancellable handler `cancel` (cumulative).
        GenericSwoftEvent wrapper = new GenericSwoftEvent(minestomEvent, new Event(method));
        vars.put("event", wrapper);

        CommandSender sender = senderFor(subject);
        try {
            new ASTExecutor(sender, vars).execute(handler.body());
        } catch (Exception e) {
            System.err.println("Error in struct-instance handler '"
                    + binding.instance().typeName() + "." + binding.field().field()
                    + " " + method + "': " + e.getMessage());
            return;
        }

        // §4.2 durability: a handler mutates its instance's fields in place (e.g.
        // `set score at b to N` on the bare bound field var). That edit is a bare
        // in-memory mutation of the struct held inside the persistent row — it
        // never dirties the row on its own, so it would be lost on the next
        // reload. Re-dirty the owning row so the next flush re-serializes the
        // whole blob, making the reactive struct the "durable stateful actor"
        // the design promises. No structural change => no index rebuild.
        PersistStore store = PersistStore.active();
        if (store != null) {
            store.markDirty(binding.rootVar(), binding.rootKey());
        }

        // flush settable args back onto the underlying event (sync bodies only),
        // mirroring the global receiver so a mutated arg propagates.
        if (argSpecs != null) {
            for (int i = 0; i < params.size() && i < argSpecs.size(); i++) {
                Arg arg = argSpecs.get(i);
                if (arg.writer() != null) {
                    try {
                        arg.writer().write(minestomEvent, handles, vars.get(params.get(i)));
                    } catch (RuntimeException ignored) {
                        // an unchanged/invalid write never breaks the event
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    /**
     * Whether a reactive field value and the event subject are the same subject.
     * Players compare by uuid (reconnect-stable); everything else by identity or
     * value equality.
     */
    private static boolean subjectMatches(Object fieldValue, Object subject) {
        if (fieldValue == subject) {
            return true;
        }
        if (fieldValue == null || subject == null || NoneValue.isNone(fieldValue)) {
            return false;
        }
        if (fieldValue instanceof Player a && subject instanceof Player b) {
            return a.getUuid().equals(b.getUuid());
        }
        return fieldValue.equals(subject);
    }

    /**
     * Whether the subject is a custom-specialized value (§4.4): a custom mob
     * (has a {@code mob Ghoul} def) or a custom item. Such a value owns its
     * behavior in its own declaration and is skipped by struct-instance dispatch.
     */
    private static boolean isCustomSpecialized(Object subject) {
        if (subject instanceof SwoftMob mob) {
            return mob.getDef() != null;
        }
        if (subject instanceof ItemStack stack) {
            return ItemRegistry.customId(stack) != null;
        }
        return false;
    }

    private static Object genericSubject(net.minestom.server.event.Event event) {
        if (event instanceof PlayerEvent playerEvent) {
            try {
                Player player = playerEvent.getPlayer();
                if (player != null) {
                    return player;
                }
            } catch (Throwable ignored) {
                // fall through
            }
        }
        return NoneValue.INSTANCE;
    }

    private static Object readProp(net.minestom.server.event.Event event,
            Map<String, Handle> handles, String name) {
        Handle handle = handles.get(name.toLowerCase(Locale.ROOT));
        if (handle == null) {
            return NoneValue.INSTANCE;
        }
        return EventPropertyResolver.read(event, handle);
    }

    private static CommandSender senderFor(Object subject) {
        if (subject instanceof CommandSender sender) {
            return sender;
        }
        try {
            return MinecraftServer.getCommandManager().getConsoleSender();
        } catch (Throwable t) {
            return SystemSender.INSTANCE;
        }
    }
}
