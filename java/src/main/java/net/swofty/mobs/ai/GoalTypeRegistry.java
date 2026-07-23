package net.swofty.mobs.ai;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Registry of the program's reusable top-level goal TYPES (design v1.9.0 §3),
 * keyed by name. Populated at load from the parsed {@link GoalTypeModel} set and
 * cleared on hot reload / mob-type teardown through the central
 * {@link net.swofty.reload.ReloadRegistry} so no ghost lifecycle survives a
 * reload (a {@code goals: [Chase]} reference re-resolves against the freshly
 * loaded set).
 */
public final class GoalTypeRegistry {

    private static final Map<String, GoalLifecycle> TYPES = new ConcurrentHashMap<>();

    private GoalTypeRegistry() {
    }

    /** Drop every registered goal type (reload teardown). */
    public static void clear() {
        TYPES.clear();
    }

    /** Register (or replace) the lifecycle for goal type {@code name}. */
    public static void register(String name, GoalLifecycle lifecycle) {
        TYPES.put(name, lifecycle);
    }

    /** The lifecycle for goal type {@code name}, or null when undeclared. */
    public static GoalLifecycle get(String name) {
        return TYPES.get(name);
    }

    public static int size() {
        return TYPES.size();
    }
}
