package net.swofty.runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Script-visible dictionary value (design phase-10 §1). Keys are String OR
 * Integer — one key type per map, chosen by the map's declared/inferred key
 * type; values are heterogeneous or homogeneous. Insertion-ordered and backed
 * by a LinkedHashMap so {@code loop m as k -&gt; v} iterates in insertion order.
 *
 * <p>Keys are boxed {@link Object}s so an Integer-keyed map stores
 * {@link Integer} keys (value equality via {@code Integer.equals}, clean unlike
 * floats) alongside the original String-keyed maps. The runtime never mixes key
 * types within one map — the checker enforces K — so a lookup with the wrong
 * boxed type simply misses.
 *
 * <p>Maps are MUTABLE REFERENCE values, matching lists: passing a map around,
 * binding it to a variable, or reading it back from a persistent all share the
 * one underlying object, so {@code map_set} on any handle is seen everywhere.
 *
 * <p>Being a {@link java.util.Map} subtype, a MapValue flows unchanged through
 * every generic map consumer already in the runtime (packet payload builders,
 * NBT tag trees, storage-config objects). The dedicated class only exists so
 * {@code is a Map} / display formatting / persistence can recognise a
 * script-level map distinctly.
 */
public final class MapValue extends LinkedHashMap<Object, Object> {

    public MapValue() {
        super();
    }

    public MapValue(Map<?, ? extends Object> source) {
        super(source);
    }

    /**
     * The persistence flush thread serializes a live cached map off the
     * script/tick thread. Script mutation goes through {@link #put}/
     * {@link #remove} (map_set / map_delete / index-assign), so those two
     * mutators and {@link #snapshot} synchronize on this instance's monitor:
     * a flush can never iterate the map while a put/remove is restructuring
     * it, which is what threw ConcurrentModificationException and killed the
     * flush loop before. The lock is held only for the O(size) structural
     * op or copy — script reads (get/containsKey/size/keySet) stay lock-free.
     */
    @Override
    public synchronized Object put(Object key, Object value) {
        return super.put(key, value);
    }

    @Override
    public synchronized Object remove(Object key) {
        return super.remove(key);
    }

    /**
     * A consistent copy for cross-thread serialization (the persistence flush
     * thread). Taken under the same monitor as {@link #put}/{@link #remove} so
     * a concurrent script-thread mutation cannot ConcurrentModify the copy.
     */
    public synchronized Map<Object, Object> snapshot() {
        return new LinkedHashMap<>(this);
    }

    /**
     * {@code { "a": 1, "b": 2 }} style rendering for println/display. String
     * keys are quoted; Integer keys render bare ({@code { 1: "x", 2: "y" }}).
     */
    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<Object, Object> entry : entrySet()) {
            if (!first) {
                sb.append(", ");
            }
            first = false;
            Object key = entry.getKey();
            if (key instanceof String) {
                sb.append('"').append(key).append("\": ");
            } else {
                sb.append(key).append(": ");
            }
            sb.append(Values.displayString(entry.getValue()));
        }
        return sb.append('}').toString();
    }
}
