package net.swofty.model;

import java.util.ArrayList;
import java.util.List;

/**
 * A {@code struct Name { [schema: N] field: Type [= default] ... [migrate to N
 * { ... }] }} declaration (§1): a nominal record type. Fields keep their source
 * order — that order is the runtime field-map order and the persistence
 * serialization order. A struct is a mutable reference type at runtime (see
 * StructValue).
 *
 * <p>{@code schema} is the current schema version (default 1) of a persistent
 * struct; {@code migrations} carries its {@code migrate to N} blocks used to
 * upgrade older stored rows (Tier-2 versioned migration). Non-persistent /
 * unversioned structs keep schema 1 and no migrations.
 */
public record StructDefModel(
        String name,
        List<StructFieldModel> fields,
        List<ReactiveFieldModel> reactive,
        int schema,
        List<MigrateBlockModel> migrations,
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

    /** The current schema version, clamped to at least 1 (default 1). */
    public int schemaVersion() {
        return Math.max(1, schema);
    }

    /**
     * The declared {@code migrate to N} blocks in ascending {@code toVersion}
     * order (never null). The load path runs these to upgrade a stored row from
     * its recorded schema version up to {@link #schemaVersion()}.
     */
    public List<MigrateBlockModel> migrationsInOrder() {
        List<MigrateBlockModel> out =
                new ArrayList<>(migrations == null ? List.of() : migrations);
        out.sort((a, b) -> Integer.compare(a.toVersion(), b.toVersion()));
        return out;
    }
}
