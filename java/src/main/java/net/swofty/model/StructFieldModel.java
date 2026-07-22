package net.swofty.model;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.DataType;

/**
 * One field of a struct declaration (§1): {@code name: Type [= default]}. The
 * default expression, when present, makes the field optional at construction —
 * the runtime fills it in for any field the constructor omits. {@code reactive}
 * carries the phase-3 {@code @EventReceiver} marker (always false for now).
 */
public record StructFieldModel(
        String name,
        DataType type,
        Expression defaultValue,
        boolean reactive,
        int line,
        int col) {

    /** True when the field has a default and may be omitted at construction. */
    public boolean hasDefault() {
        return defaultValue != null;
    }
}
