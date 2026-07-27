package net.swofty.model;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.DataType;

/**
 * persistent name [for Subject]: Type = default declaration. subject is
 * null for global scalars; type is one of the scalar types (String,
 * Integer, Double, Boolean). The default expression makes reads total:
 * a missing row resolves to it.
 *
 * <p>{@code change} is the optional declaration-attached change handler of
 * 1.10.0 §4 ({@code on_change} / {@code on_entry_change}); null when the
 * declaration carries no trailing block, which is every pre-1.10.0 program.
 */
public record PersistentDeclModel(
        String name,
        DataType subject,
        DataType type,
        Expression defaultValue,
        PersistChangeModel change,
        int line,
        int col) {

    /** A declaration with no change handler (the shape before 1.10.0 §4). */
    public PersistentDeclModel(String name, DataType subject, DataType type,
            Expression defaultValue, int line, int col) {
        this(name, subject, type, defaultValue, null, line, col);
    }
}
