package net.swofty.model;

/**
 * One declared entry in a mob's {@code tags { ... }} block (W-viewers,
 * feature 2). Two flavours:
 *
 * <ul>
 *   <li><b>Typed</b> — {@code hits: map&lt;Player, Integer&gt;} /
 *       {@code queue: list&lt;String&gt;} / {@code count: Integer}. The tag store
 *       is seeded with a live, empty container (or none for a bare scalar type)
 *       so {@code mob.tags.hits[player]} is a real, indexable, in-memory map —
 *       no NBT serialization.</li>
 *   <li><b>Value init</b> — {@code level: 5} (item-style): the type is inferred
 *       from the literal and the store seeds the value directly.</li>
 * </ul>
 */
public record MobTagDecl(String name, Kind kind, Object initValue) {

    public enum Kind {
        /** {@code map<K, V>} — seeded as an empty live map. */
        MAP,
        /** {@code list<T>} — seeded as an empty live list. */
        LIST,
        /** A scalar: a typed scalar (initValue null) or a value init. */
        SCALAR
    }

    /** A typed map/list declaration with no initial value. */
    public static MobTagDecl typed(String name, Kind kind) {
        return new MobTagDecl(name, kind, null);
    }

    /** A value-init tag (item style): {@code level: 5}. */
    public static MobTagDecl value(String name, Object initValue) {
        return new MobTagDecl(name, Kind.SCALAR, initValue);
    }
}
