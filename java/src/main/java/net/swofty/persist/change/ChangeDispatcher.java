package net.swofty.persist.change;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.command.CommandSender;
import net.minestom.server.entity.Player;
import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.async.TickDispatch;
import net.swofty.model.PersistChangeModel;
import net.swofty.model.PersistentDeclModel;
import net.swofty.nativebridge.representation.BaseType;
import net.swofty.persist.PersistStore;
import net.swofty.props.NoneValue;
import net.swofty.runtime.MapValue;
import net.swofty.structs.StructValue;

/**
 * Change-event dispatch (design 1.10.0 §4.1), one per {@link PersistStore}.
 *
 * <p>The four rules it implements, in the order they bite:
 * <ol>
 *   <li><b>Fires on EVERY server, including the writer.</b> The originating
 *       server dispatches from its own write path and every other server
 *       dispatches when it applies the broadcast, so a {@code broadcast} inside
 *       a handler reaches the writer's own players too — network-only firing
 *       would silence exactly the wrong server. {@code caused_here} is the flag
 *       that tells them apart (always true in {@code mode: standalone}).</li>
 *   <li><b>Only on a real change.</b> The new value is compared BY VALUE against
 *       a per-row shadow, so {@code set x to x} fires nothing — and so does a
 *       converging cascade, which is cascade guard layer 1 (§5.1) for free.</li>
 *   <li><b>Never on load/restore.</b> A session acquire+load for a joining
 *       player and the boot-time replica load call {@link #seed} instead, which
 *       updates the shadow silently. Without that, every join would storm every
 *       handler.</li>
 *   <li><b>Collections react per ENTRY.</b> {@code old is none} is an insert,
 *       {@code new is none} a remove, both present an update — and a bulk clear
 *       or replace is BATCHED and CAPPED, so clearing a 10k map fires the cap
 *       and one summary line instead of ten thousand handlers.</li>
 * </ol>
 *
 * <p>Handlers run on the TICK thread (the bodies are sync-coloured — an
 * {@code await}/{@code wait} inside is the existing colour error, and
 * {@code async { }} is the way out). A write already on the tick thread
 * dispatches inline, so the reaction lands in the same tick as the write; an
 * off-thread write (the bus subscriber, a virtual-thread task) parks the batch
 * on the next tick.
 */
public final class ChangeDispatcher {

    /**
     * §4.1: how many per-entry events one bulk change may fire. Past this the
     * remainder is dropped with a single summary line — the whole point of the
     * cap is that clearing a huge map must not storm the tick thread.
     */
    private static final String ENTRY_CAP_PROPERTY = "swoft.persist.change.entry_cap";

    private static final int DEFAULT_ENTRY_CAP = 64;

    /** var -&gt; key -&gt; the last value handlers were told about (a snapshot). */
    private final Map<String, ConcurrentHashMap<String, Object>> shadow = new ConcurrentHashMap<>();

    private final PersistStore store;

    public ChangeDispatcher(PersistStore store) {
        this.store = store;
    }

    /** One dispatched reaction: an entry key (null for a scalar), old, new. */
    private record Event(Object entryKey, Object old, Object next) {
    }

    /**
     * Record a value WITHOUT firing anything — a load or a restore (§4.1: "a
     * player joining and their values loading is a restore, not a change";
     * likewise the boot-time replica load). A null value means the row is
     * absent, so its shadow is the declared default.
     */
    public void seed(String var, String key, Object value) {
        if (ChangeRegistry.handlerFor(var) == null) {
            return;
        }
        rows(var).put(key, snapshot(value != null ? value : store.defaultOf(var)));
    }

    /** Forget a row's shadow — eviction, so a later re-load re-seeds it. */
    public void forget(String var, String key) {
        ConcurrentHashMap<String, Object> rows = shadow.get(var);
        if (rows != null) {
            rows.remove(key);
        }
    }

    /**
     * A value was actually written: diff it against the shadow and dispatch
     * whatever really changed.
     *
     * @param causedHere true on the server that made the write (§4.1)
     * @param token      the causality token the write carried (§5.3); handler
     *                   writes continue this chain one level deeper
     */
    public void observe(PersistentDeclModel decl, String key, Object value, boolean causedHere,
            CausalityToken token) {
        if (!ChangeRegistry.armed()) {
            return;
        }
        PersistChangeModel handler = ChangeRegistry.handlerFor(decl.name());
        if (handler == null) {
            return;
        }
        // the value is SNAPSHOTTED here, at change time, and the events are
        // diffed off that snapshot rather than off the live row. Collections and
        // structs are reference values, so a handler parked on the next tick
        // would otherwise be handed a 'new' that a later write had already
        // mutated underneath it - reading the value at DISPATCH time is the racy
        // version of this, and pairing it with the 'old' of the earlier write
        // would be worse than either.
        Object next = snapshot(value);
        Object previous = rows(decl.name()).put(key, next);
        Object old = previous != null ? previous : snapshot(store.defaultOf(decl.name()));
        List<Event> events = handler.isEntry()
                ? entryEvents(decl, old, next)
                : scalarEvents(old, next);
        if (events.isEmpty()) {
            return;
        }
        dispatch(decl, handler, key, events, causedHere, token);
    }

    // ------------------------------------------------------------------
    // diffing
    // ------------------------------------------------------------------

    private static List<Event> scalarEvents(Object old, Object next) {
        if (valueEquals(old, next)) {
            return List.of();
        }
        return List.of(new Event(null, old, next));
    }

    /**
     * §4.1 collections: one event per changed ENTRY. A map diffs by key, a list
     * by index; an entry missing on one side is {@code none}, which is what
     * makes {@code if old is none} an insert and {@code if new is none} a
     * remove. A bulk clear or wholesale replace therefore arrives here as a
     * batch of removals, which {@link #dispatch} caps.
     */
    private static List<Event> entryEvents(PersistentDeclModel decl, Object old, Object next) {
        if (old instanceof Map<?, ?> || next instanceof Map<?, ?>) {
            return mapEvents(asMap(old), asMap(next));
        }
        if (old instanceof List<?> || next instanceof List<?>) {
            return listEvents(asList(old), asList(next));
        }
        // not a collection after all (a mis-shaped row): fall back to the
        // whole-value comparison rather than silently reacting to nothing
        return scalarEvents(old, next);
    }

    private static List<Event> mapEvents(Map<?, ?> old, Map<?, ?> next) {
        Set<Object> keys = new LinkedHashSet<>();
        keys.addAll(old.keySet());
        keys.addAll(next.keySet());
        List<Event> events = new ArrayList<>();
        for (Object key : keys) {
            Object before = old.containsKey(key) ? old.get(key) : NoneValue.INSTANCE;
            Object after = next.containsKey(key) ? next.get(key) : NoneValue.INSTANCE;
            if (!valueEquals(before, after)) {
                events.add(new Event(key, before, after));
            }
        }
        return events;
    }

    private static List<Event> listEvents(List<?> old, List<?> next) {
        List<Event> events = new ArrayList<>();
        int size = Math.max(old.size(), next.size());
        for (int i = 0; i < size; i++) {
            Object before = i < old.size() ? old.get(i) : NoneValue.INSTANCE;
            Object after = i < next.size() ? next.get(i) : NoneValue.INSTANCE;
            if (!valueEquals(before, after)) {
                events.add(new Event(i, before, after));
            }
        }
        return events;
    }

    private static Map<?, ?> asMap(Object value) {
        return value instanceof Map<?, ?> map ? map : Map.of();
    }

    private static List<?> asList(Object value) {
        return value instanceof List<?> list ? list : List.of();
    }

    // ------------------------------------------------------------------
    // dispatch
    // ------------------------------------------------------------------

    private void dispatch(PersistentDeclModel decl, PersistChangeModel handler, String key,
            List<Event> events, boolean causedHere, CausalityToken token) {
        int cap = entryCap();
        List<Event> batch = events;
        if (handler.isEntry() && events.size() > cap) {
            batch = List.copyOf(events.subList(0, cap));
            System.out.println("[persist] '" + decl.name() + "' changed " + events.size()
                    + " entries at once - fired the first " + cap
                    + " entry handler(s) and suppressed " + (events.size() - cap)
                    + " (bulk clear/replace; raise -D" + ENTRY_CAP_PROPERTY + " to see more)");
        }
        List<Event> dispatched = batch;
        // a batch that cannot run inline is parked on the next tick, and a hot
        // reload can land in between: run it only if the handlers it was built
        // against are still the installed ones, so a queued reaction can never
        // execute a torn-down body against the freshly-loaded program.
        long generation = ChangeRegistry.generation();
        TickDispatch.post(() -> {
            if (ChangeRegistry.generation() != generation) {
                return;
            }
            for (Event event : dispatched) {
                run(decl, handler, key, event, causedHere, token);
            }
        });
    }

    private void run(PersistentDeclModel decl, PersistChangeModel handler, String key,
            Event event, boolean causedHere, CausalityToken token) {
        Map<String, Object> vars = new HashMap<>();
        CommandSender sender = null;
        if (handler.bindsName("player")) {
            Object subject = resolveSubject(decl, key);
            vars.put("player", subject);
            if (subject instanceof Player player) {
                sender = player;
            }
        }
        if (handler.bindsName("key")) {
            vars.put("key", handler.isEntry() ? event.entryKey() : declKey(decl, key));
        }
        vars.put("old", event.old());
        vars.put("new", event.next());
        vars.put("caused_here", causedHere);

        CausalityToken previous = Causality.enter(token);
        // a write inside the handler must land in the store the change came
        // from, which is only ambiguous in the two-server harness (two stores,
        // one JVM) - production has exactly one and this is a no-op
        boolean swapped = PersistStore.active() != store;
        PersistStore previousStore = swapped ? PersistStore.swapActive(store) : null;
        try {
            new ASTExecutor(sender, vars).execute(handler.body());
        } catch (ScriptError e) {
            System.err.println("[persist] the " + handler.kind() + " handler of '"
                    + decl.name() + "' failed: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("[persist] the " + handler.kind() + " handler of '"
                    + decl.name() + "' failed: " + e);
        } finally {
            if (swapped) {
                PersistStore.swapActive(previousStore);
            }
            Causality.exit(previous);
        }
    }

    /**
     * The declaration's own key as the handler sees it: a Player/OfflinePlayer
     * subject resolves back from its stored uuid (the live player when they are
     * online here, the offline identity otherwise), an Integer-keyed
     * declaration hands back a number, everything else the key string.
     */
    private static Object resolveSubject(PersistentDeclModel decl, String key) {
        if (decl.subject() == null || key == null || key.isEmpty()) {
            return NoneValue.INSTANCE;
        }
        BaseType subject = decl.subject().getBaseType();
        if (subject == BaseType.PLAYER || subject == BaseType.OFFLINE_PLAYER) {
            Object online = onlinePlayer(key);
            if (online != null) {
                return online;
            }
            try {
                return net.swofty.players.SeenPlayersStore.byUuid(key);
            } catch (Exception e) {
                return NoneValue.INSTANCE;
            }
        }
        return declKey(decl, key);
    }

    private static Object onlinePlayer(String key) {
        try {
            return net.minestom.server.MinecraftServer.getConnectionManager()
                    .getOnlinePlayerByUuid(java.util.UUID.fromString(key));
        } catch (Exception e) {
            return null;
        }
    }

    private static Object declKey(PersistentDeclModel decl, String key) {
        if (decl.subject() != null && decl.subject().getBaseType() == BaseType.INTEGER) {
            try {
                return Integer.valueOf(key);
            } catch (NumberFormatException e) {
                return key;
            }
        }
        return key;
    }

    private ConcurrentHashMap<String, Object> rows(String var) {
        return shadow.computeIfAbsent(var, k -> new ConcurrentHashMap<>());
    }

    private static int entryCap() {
        try {
            String configured = System.getProperty(ENTRY_CAP_PROPERTY);
            if (configured != null) {
                return Math.max(1, Integer.parseInt(configured.trim()));
            }
        } catch (Exception ignored) {
            // a malformed override falls back to the documented default
        }
        return DEFAULT_ENTRY_CAP;
    }

    // ------------------------------------------------------------------
    // value snapshots and by-value comparison
    // ------------------------------------------------------------------

    /**
     * A defensive copy of a value, so the shadow keeps what handlers were last
     * told even when the live value is mutated in place afterwards. Collections
     * and structs are reference values in this language ({@code set m at k to v}
     * mutates the map every handle shares), so without the copy old and new
     * would be the same object and no change would ever be visible.
     */
    private static Object snapshot(Object value) {
        if (value instanceof MapValue map) {
            MapValue copy = new MapValue();
            for (Map.Entry<Object, Object> entry : map.snapshot().entrySet()) {
                copy.put(entry.getKey(), snapshot(entry.getValue()));
            }
            return copy;
        }
        if (value instanceof Map<?, ?> map) {
            Map<Object, Object> copy = new LinkedHashMap<>();
            for (Map.Entry<?, ?> entry : map.entrySet()) {
                copy.put(entry.getKey(), snapshot(entry.getValue()));
            }
            return copy;
        }
        if (value instanceof List<?> list) {
            List<Object> copy = new ArrayList<>(list.size());
            for (Object element : list) {
                copy.add(snapshot(element));
            }
            return copy;
        }
        if (value instanceof StructValue struct) {
            LinkedHashMap<String, Object> fields = new LinkedHashMap<>();
            for (Map.Entry<String, Object> entry : struct.fields().entrySet()) {
                fields.put(entry.getKey(), snapshot(entry.getValue()));
            }
            return new StructValue(struct.typeName(), fields);
        }
        return value;
    }

    /**
     * §4.1 "only on real change": {@code new != old} BY VALUE. Containers and
     * structs compare structurally (identity would call every in-place mutation
     * a non-change), numbers compare numerically so an Integer 5 and a Double
     * 5.0 of the same row are the same value, and {@code none} equals
     * {@code none}.
     */
    static boolean valueEquals(Object a, Object b) {
        if (a == b) {
            return true;
        }
        if (NoneValue.isNone(a) || NoneValue.isNone(b)) {
            return NoneValue.isNone(a) && NoneValue.isNone(b);
        }
        if (a instanceof Number left && b instanceof Number right) {
            if (left instanceof Double || right instanceof Double
                    || left instanceof Float || right instanceof Float) {
                return left.doubleValue() == right.doubleValue();
            }
            return left.longValue() == right.longValue();
        }
        if (a instanceof Map<?, ?> left && b instanceof Map<?, ?> right) {
            if (left.size() != right.size()) {
                return false;
            }
            for (Map.Entry<?, ?> entry : left.entrySet()) {
                if (!right.containsKey(entry.getKey())
                        || !valueEquals(entry.getValue(), right.get(entry.getKey()))) {
                    return false;
                }
            }
            return true;
        }
        if (a instanceof List<?> left && b instanceof List<?> right) {
            if (left.size() != right.size()) {
                return false;
            }
            for (int i = 0; i < left.size(); i++) {
                if (!valueEquals(left.get(i), right.get(i))) {
                    return false;
                }
            }
            return true;
        }
        if (a instanceof StructValue left && b instanceof StructValue right) {
            if (!left.typeName().equals(right.typeName())
                    || left.fields().size() != right.fields().size()) {
                return false;
            }
            for (Map.Entry<String, Object> entry : left.fields().entrySet()) {
                if (!right.fields().containsKey(entry.getKey())
                        || !valueEquals(entry.getValue(), right.fields().get(entry.getKey()))) {
                    return false;
                }
            }
            return true;
        }
        return Objects.equals(a, b);
    }
}
