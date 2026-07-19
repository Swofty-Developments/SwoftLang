package net.swofty;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.minestom.server.instance.Instance;

/**
 * Name table for Minestom instances (Minestom itself keys instances by UUID
 * only). Populated by the bootstrap / host server.
 */
public final class InstanceRegistry {
    private static final Map<String, Instance> INSTANCES = new ConcurrentHashMap<>();

    private InstanceRegistry() {
    }

    public static void register(String name, Instance instance) {
        INSTANCES.put(name, instance);
    }

    public static Instance get(String name) {
        return INSTANCES.get(name);
    }

    public static void unregister(String name) {
        INSTANCES.remove(name);
    }

    public static String nameOf(Instance instance) {
        for (Map.Entry<String, Instance> entry : INSTANCES.entrySet()) {
            if (entry.getValue() == instance) {
                return entry.getKey();
            }
        }
        return instance.getUuid().toString();
    }

    public static void clear() {
        INSTANCES.clear();
    }
}
