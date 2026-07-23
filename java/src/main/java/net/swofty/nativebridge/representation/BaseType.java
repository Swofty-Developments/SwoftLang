package net.swofty.nativebridge.representation;

public enum BaseType {
    STRING,
    INTEGER,
    DOUBLE,
    BOOLEAN,
    PLAYER,
    OFFLINE_PLAYER,
    LOCATION,
    WORLD,
    ITEM,
    MOB,
    BLOCK,
    DISPLAY,
    SONG,
    SKIN,
    CANVAS,
    SCHEDULE,
    WORLD_LOADER,
    ENTITY,
    VEC,
    LIST,
    MAP,
    OPTIONAL,
    EITHER,
    // A Future<T> value handle (§1.8.0): async work that will yield a T. The
    // payload type lives in DataType.subTypes[0]. Futures are runtime-only
    // (never persisted), so no storage dispatch resolves them.
    FUTURE,
    // A nominal struct / custom-type reference carried by name (§1 structs,
    // §2 nominal custom types). The name lives in DataType.typeName; the
    // struct registry resolves it to a StructDefModel for construction and
    // persistence dispatch.
    STRUCT,
    UNKNOWN
}