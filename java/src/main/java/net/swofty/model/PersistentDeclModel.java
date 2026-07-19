package net.swofty.model;

import net.swofty.nativebridge.execution.Expression;
import net.swofty.nativebridge.representation.DataType;

/**
 * persistent name [for Subject]: Type = default declaration. subject is
 * null for global scalars; type is one of the scalar types (String,
 * Integer, Double, Boolean). The default expression makes reads total:
 * a missing row resolves to it.
 */
public record PersistentDeclModel(
        String name,
        DataType subject,
        DataType type,
        Expression defaultValue,
        int line,
        int col) {
}
