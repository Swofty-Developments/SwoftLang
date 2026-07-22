package net.swofty.structs;

import java.util.LinkedHashMap;
import java.util.Map;

import net.swofty.ScriptError;
import net.swofty.model.StructDefModel;
import net.swofty.props.DynamicPropertyOwner;
import net.swofty.props.NoneValue;

/**
 * A runtime struct instance (§1.4): a mutable reference object carrying an
 * ordered field map of typed values. It is a reference type like map/list —
 * two variables holding the same StructValue see each other's field mutations
 * (aliasing is real), because field-set writes the backing map in place.
 *
 * <p>Property access ({@code g.name}) and property set ({@code set g.name to v})
 * flow through {@link DynamicPropertyOwner}, so PathResolver reads and writes
 * fields directly on this object — including deep paths ({@code g.hq.x}) and
 * chains rooted at a struct — with no special-casing.
 */
public final class StructValue implements DynamicPropertyOwner {
    private final String typeName;
    // insertion order == struct declaration field order (§1)
    private final LinkedHashMap<String, Object> fields;

    /** Build a fresh instance for the given struct type with the given fields. */
    public StructValue(String typeName, LinkedHashMap<String, Object> fields) {
        this.typeName = typeName;
        this.fields = fields;
    }

    /** The nominal struct type name (e.g. "Guild"). */
    public String typeName() {
        return typeName;
    }

    /** The live backing field map (ordered). Mutations are visible to aliases. */
    public Map<String, Object> fields() {
        return fields;
    }

    public boolean hasField(String name) {
        return fields.containsKey(name);
    }

    public Object getField(String name) {
        return fields.get(name);
    }

    /** Write a field in place. Aliasing means every holder sees the change. */
    public void setField(String name, Object value) {
        fields.put(name, value);
    }

    /**
     * {@code g.copy()} (§1.4): a shallow structural copy — a new struct with the
     * same field values. Nested reference values (lists, maps, nested structs)
     * are shared with the original, not deep-copied.
     */
    public StructValue copy() {
        return new StructValue(typeName, new LinkedHashMap<>(fields));
    }

    // -------------------------- DynamicPropertyOwner --------------------------

    @Override
    public boolean hasDynamicProperty(String name) {
        return fields.containsKey(name);
    }

    @Override
    public Object getDynamicProperty(String name, int line, int col) {
        if (!fields.containsKey(name)) {
            throw new ScriptError("struct '" + typeName + "' has no field '" + name + "'",
                    line, col);
        }
        Object value = fields.get(name);
        return value == null ? NoneValue.INSTANCE : value;
    }

    @Override
    public void setDynamicProperty(String name, Object value, int line, int col) {
        if (!fields.containsKey(name)) {
            throw new ScriptError("struct '" + typeName + "' has no field '" + name + "'",
                    line, col);
        }
        fields.put(name, value);
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder(typeName).append(" {");
        boolean first = true;
        for (Map.Entry<String, Object> entry : fields.entrySet()) {
            if (!first) {
                sb.append(", ");
            }
            first = false;
            sb.append(entry.getKey()).append(": ").append(entry.getValue());
        }
        return sb.append("}").toString();
    }
}
