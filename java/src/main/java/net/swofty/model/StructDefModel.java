package net.swofty.model;

import java.util.List;

/**
 * A {@code struct Name { field: Type [= default] ... }} declaration (§1): a
 * nominal record type. Fields keep their source order — that order is the
 * runtime field-map order and the persistence serialization order. A struct
 * is a mutable reference type at runtime (see StructValue).
 */
public record StructDefModel(
        String name,
        List<StructFieldModel> fields,
        List<ReactiveFieldModel> reactive,
        int line,
        int col) {

    /** The field of the given name, or null if the struct has no such field. */
    public StructFieldModel field(String fieldName) {
        for (StructFieldModel field : fields) {
            if (field.name().equals(fieldName)) {
                return field;
            }
        }
        return null;
    }

    /** True when this struct declares at least one {@code @EventReceiver} field (§4). */
    public boolean hasReactiveFields() {
        return reactive != null && !reactive.isEmpty();
    }
}
