package net.swofty.compiler;

import java.util.HashMap;
import java.util.Map;

/**
 * Global registry of user-declared SwoftLang functions: flat-script
 * functions, entry-module functions, and the exported functions of every
 * loaded module. Module-private functions live only in the
 * {@link ModuleRegistry}. Two different modules exporting the same name is
 * a load error naming both modules; flat scripts keep the historical
 * last-one-wins behavior.
 */
public class FunctionRegistry {
    private static final Map<String, SwoftFunction> functions = new HashMap<>();

    public static void register(SwoftFunction function) {
        checkRegisterable(function);
        functions.put(function.name(), function);
    }

    /**
     * Validate that {@link #register} would succeed, without committing —
     * bundle loads stage all their checks before registering anything
     */
    public static void checkRegisterable(SwoftFunction function) {
        SwoftFunction existing = functions.get(function.name());
        if (existing != null && existing != function
                && existing.module() != null && function.module() != null
                && !existing.module().equals(function.module())) {
            throw new IllegalStateException("duplicate function '" + function.name()
                    + "': exported by both module '" + existing.module()
                    + "' and module '" + function.module() + "'");
        }
    }

    /**
     * Drop a registration, but only if the name still maps to this exact
     * instance (used when a flat-compiled script turns out to be a module
     * of another entry's bundle and its standalone copy is discarded)
     */
    public static void unregister(SwoftFunction function) {
        functions.remove(function.name(), function);
    }

    public static SwoftFunction lookup(String name) {
        return functions.get(name);
    }

    public static void clear() {
        functions.clear();
    }
}
