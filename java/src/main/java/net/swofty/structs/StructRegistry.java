package net.swofty.structs;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import net.swofty.ScriptError;
import net.swofty.model.StructDefModel;

/**
 * Global registry of struct declarations (§1), keyed by the nominal type name
 * (e.g. "Guild"). Populated at load time from every script's {@code structs}
 * section, cleared on reload. Construction reads it to know a struct's field
 * order and defaults; the persistence layer reads it to dispatch each field by
 * its declared type.
 */
public final class StructRegistry {
    private static final Map<String, StructDefModel> DEFS = new ConcurrentHashMap<>();

    private StructRegistry() {
    }

    public static void clear() {
        DEFS.clear();
    }

    public static void register(StructDefModel def) {
        if (DEFS.putIfAbsent(def.name(), def) != null) {
            System.err.println("Error: duplicate struct type '" + def.name()
                    + "' - keeping the first");
        }
    }

    /** The struct declaration for a type name, or null when none is declared. */
    public static StructDefModel get(String name) {
        return name == null ? null : DEFS.get(name);
    }

    public static StructDefModel require(String name) {
        StructDefModel def = get(name);
        if (def == null) {
            throw new ScriptError("unknown struct type '" + name + "'");
        }
        return def;
    }

    public static boolean isStruct(String name) {
        return name != null && DEFS.containsKey(name);
    }
}
