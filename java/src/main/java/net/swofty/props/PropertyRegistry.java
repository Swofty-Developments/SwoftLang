package net.swofty.props;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Deque;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Typed property whitelist keyed by owner class. Lookup walks the exact
 * class, the full superclass chain, and all transitive interfaces; the most
 * specific registration wins. Registration is merge-safe: rows for the same
 * class accumulate instead of clobbering each other.
 */
public final class PropertyRegistry {
    private static final Map<Class<?>, Map<String, PropertyDef>> DEFS = new ConcurrentHashMap<>();
    private static final Map<Class<?>, Map<String, PropertyDef>> RESOLVED = new ConcurrentHashMap<>();

    private PropertyRegistry() {
    }

    public static void register(PropertyDef def) {
        DEFS.computeIfAbsent(def.owner(), c -> new ConcurrentHashMap<>())
                .put(def.name().toLowerCase(), def);
        RESOLVED.clear();
    }

    public static Optional<PropertyDef> lookup(Class<?> type, String name) {
        return Optional.ofNullable(RESOLVED.computeIfAbsent(type, PropertyRegistry::flatten)
                .get(name.toLowerCase()));
    }

    public static void clear() {
        DEFS.clear();
        RESOLVED.clear();
    }

    private static Map<String, PropertyDef> flatten(Class<?> type) {
        List<Class<?>> order = new ArrayList<>();
        for (Class<?> c = type; c != null; c = c.getSuperclass()) {
            order.add(c);
        }
        Set<Class<?>> seen = new HashSet<>(order);
        Deque<Class<?>> queue = new ArrayDeque<>();
        for (Class<?> c = type; c != null; c = c.getSuperclass()) {
            for (Class<?> iface : c.getInterfaces()) {
                if (seen.add(iface)) {
                    queue.add(iface);
                }
            }
        }
        while (!queue.isEmpty()) {
            Class<?> iface = queue.poll();
            order.add(iface);
            for (Class<?> parent : iface.getInterfaces()) {
                if (seen.add(parent)) {
                    queue.add(parent);
                }
            }
        }

        Map<String, PropertyDef> merged = new HashMap<>();
        for (Class<?> c : order) {
            Map<String, PropertyDef> rows = DEFS.get(c);
            if (rows != null) {
                rows.forEach(merged::putIfAbsent);
            }
        }
        return merged;
    }
}
