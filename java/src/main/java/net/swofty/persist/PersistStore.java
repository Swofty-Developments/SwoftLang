package net.swofty.persist;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

import com.google.gson.JsonElement;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;

import net.swofty.ASTExecutor;
import net.swofty.ScriptError;
import net.swofty.model.PersistentDeclModel;
import net.swofty.model.StorageBackendModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.nativebridge.representation.BaseType;
import net.swofty.props.NoneValue;

/**
 * In-memory facade over a SwoftStorage backend. Every declared persistent
 * variable is loaded into a ConcurrentHashMap at init (bad rows warn and
 * fall back to the declared default), so script-side get/set never touch
 * IO. Writes mark rows dirty; a virtual-thread flush loop pushes dirty
 * rows to the backend every flush_ticks, and a JVM shutdown hook (plus
 * the engine/server shutdown path) does a final flush.
 */
public final class PersistStore {
    private static volatile PersistStore active;

    private final Map<String, PersistentDeclModel> declarations = new LinkedHashMap<>();
    private final Map<String, Object> defaults = new HashMap<>();
    private final SwoftStorage storage;
    private final long flushMillis;
    private final ConcurrentHashMap<String, ConcurrentHashMap<String, Object>> cache =
            new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Set<String>> dirty = new ConcurrentHashMap<>();
    private final AtomicBoolean closed = new AtomicBoolean(false);
    private volatile boolean running = true;
    private Thread flushThread;
    private Thread shutdownHook;

    private PersistStore(List<PersistentDeclModel> decls, SwoftStorage storage, long flushMillis) {
        this.storage = storage;
        this.flushMillis = flushMillis;
        for (PersistentDeclModel decl : decls) {
            if (!isPersistable(decl.type())) {
                System.err.println("Warning: persistent '" + decl.name()
                        + "' has non-persistable type " + decl.type()
                        + " - skipping (persistables are the scalar types and"
                        + " map<Scalar>; store primitive fields instead)");
                continue;
            }
            declarations.put(decl.name(), decl);
        }
    }

    /**
     * Build, load, and activate a store; any previously active store is
     * flushed and closed first. A null config means the default files
     * backend ("swoftlang-data", 30s flush).
     */
    public static synchronized PersistStore initialize(List<PersistentDeclModel> decls,
            StorageConfigModel config) {
        // defense in depth behind the checker's reserved-'__'-prefix rule: a
        // user persistent named like the seen-players store would share its
        // storage namespace and destroy every seen row on the next flush
        for (PersistentDeclModel decl : decls) {
            if (net.swofty.players.SeenPlayersStore.RESERVED_VAR.equals(decl.name())) {
                throw new IllegalArgumentException("persistent '" + decl.name()
                        + "' collides with the reserved seen-players store");
            }
        }
        shutdownActive();
        StorageConfigModel effective = config != null ? config : StorageConfigModel.defaults();
        SwoftStorage storage = createStorage(effective.backend());
        long flushMillis = Math.max(1, effective.flushTicks()) * 50L;

        PersistStore store = new PersistStore(decls, storage, flushMillis);
        store.evaluateDefaults();
        store.loadAll();
        store.startFlushLoop();
        store.shutdownHook = new Thread(store::shutdownInternal, "swoft-persist-shutdown");
        Runtime.getRuntime().addShutdownHook(store.shutdownHook);
        active = store;
        System.out.println("PersistStore: " + store.declarations.size()
                + " persistent variable(s) on backend '" + effective.backend().kind()
                + "', flush every " + effective.flushTicks() + " tick(s)");
        return store;
    }

    /** The active store, or null when persistence is not initialized. */
    public static PersistStore active() {
        return active;
    }

    /** Flush and close the active store, if any. */
    public static synchronized void shutdownActive() {
        PersistStore store = active;
        if (store != null) {
            store.shutdown();
        }
    }

    /**
     * Public backend factory: phase-6 world loaders reuse the same
     * files/sqlite/mysql/mongodb backends for polar world blobs
     * (polar_storage_loader, design 6B).
     */
    public static SwoftStorage createBackend(StorageBackendModel backend) {
        return createStorage(backend);
    }

    private static SwoftStorage createStorage(StorageBackendModel backend) {
        switch (backend.kind()) {
            case "files":
                return new FilesStorage(backend.path() != null ? backend.path() : "swoftlang-data");
            case "sqlite":
                return new SqliteStorage(backend.path() != null ? backend.path() : "swoftlang-data.db");
            case "mysql":
                return new MysqlStorage(
                        backend.host() != null ? backend.host() : "localhost",
                        backend.port() > 0 ? backend.port() : 3306,
                        backend.database(), backend.user(), backend.password());
            case "mongodb":
                return new MongoStorage(backend.uri() != null ? backend.uri()
                        : "mongodb://localhost:27017/swoftlang");
            default:
                throw new IllegalArgumentException("Unknown storage backend kind: " + backend.kind());
        }
    }

    /**
     * Read one persistent value from the cache; a missing row resolves to
     * the declared default. Never blocks on IO.
     * @param key "" for the global scalar, otherwise the subject key
     */
    public Object get(String name, String key) {
        warnIfClosed("persist_get", name, key);
        PersistentDeclModel decl = requireDeclared(name);
        ConcurrentHashMap<String, Object> rows = cache.get(decl.name());
        Object value = rows != null ? rows.get(key) : null;
        if (value != null) {
            return value;
        }
        Object def = defaults.get(decl.name());
        // an absent map row must NOT hand out the shared default instance:
        // maps are mutable references, so a caller mutating it would corrupt
        // the default (and thus every other absent subject). Hand out a fresh
        // copy; it persists only if the caller writes it back with persist_set.
        if (def instanceof net.swofty.runtime.MapValue map) {
            return new net.swofty.runtime.MapValue(map);
        }
        return def;
    }

    /**
     * Write one persistent value to the cache and mark it dirty for the
     * next flush. Never blocks on IO.
     */
    public void set(String name, String key, Object value) {
        warnIfClosed("persist_set", name, key);
        PersistentDeclModel decl = requireDeclared(name);
        Object coerced = coerceRuntime(decl, value);
        cache.computeIfAbsent(decl.name(), k -> new ConcurrentHashMap<>()).put(key, coerced);
        dirty.computeIfAbsent(decl.name(), k -> ConcurrentHashMap.newKeySet()).add(key);
    }

    /**
     * A script task that outlives shutdown can still reach the cache, but
     * its writes happen after the final flush snapshot and are lost when
     * the JVM exits — never swallow that silently.
     */
    private void warnIfClosed(String op, String name, String key) {
        if (closed.get()) {
            System.err.println("Warning: " + op + " '" + name + "'" + rowLabel(key)
                    + " after the persistence store closed - the "
                    + (op.equals("persist_set") ? "write will NOT reach the backend"
                            : "read sees the last cached value")
                    + " (script task outlived shutdown?)");
        }
    }

    /** All cached rows, sorted, for the harness to print. */
    public Map<String, Map<String, Object>> dump() {
        Map<String, Map<String, Object>> out = new TreeMap<>();
        for (Map.Entry<String, ConcurrentHashMap<String, Object>> entry : cache.entrySet()) {
            out.put(entry.getKey(), new TreeMap<>(entry.getValue()));
        }
        return out;
    }

    /**
     * Push every dirty row to the backend. Runs on the flush thread and
     * the shutdown path; a failing backend keeps rows dirty for retry.
     * Synchronized so whole cycles serialize: two concurrent cycles could
     * interleave as [A unmarks+reads v1] [set(v2) re-marks] [B unmarks+
     * reads+writes v2] [A writes stale v1], consuming the dirty marker
     * while the backend holds v1 — v2 would then never flush again. The
     * per-key unmark-before-read below stays load-bearing for the plain
     * set()-vs-single-flusher race.
     */
    public synchronized void flush() {
        for (Map.Entry<String, Set<String>> entry : dirty.entrySet()) {
            String var = entry.getKey();
            Set<String> keys = entry.getValue();
            if (keys.isEmpty()) {
                continue;
            }
            Map<String, JsonElement> batch = new LinkedHashMap<>();
            List<String> taken = List.copyOf(keys);
            ConcurrentHashMap<String, Object> rows = cache.get(var);
            // Serialization (toJson) is inside the try alongside writeBatch: a
            // failure to serialize a row must keep the whole batch dirty for
            // the next cycle, never escape flush() and terminate the loop.
            try {
                for (String key : taken) {
                    // Unmark before reading: a concurrent set() re-adds the
                    // marker, so its write can never be lost between cycles
                    keys.remove(key);
                    Object value = rows != null ? rows.get(key) : null;
                    if (value != null) {
                        batch.put(key, toJson(value));
                    }
                }
                if (batch.isEmpty()) {
                    continue;
                }
                storage.writeBatch(var, batch);
            } catch (Exception e) {
                System.err.println("Warning: persistence flush failed for '" + var
                        + "': " + e.getMessage() + " - retrying next cycle");
                keys.addAll(taken);
            }
        }
    }

    /** Stop the flush loop, flush once more, and close the backend. */
    public void shutdown() {
        if (shutdownInternal() && shutdownHook != null) {
            try {
                Runtime.getRuntime().removeShutdownHook(shutdownHook);
            } catch (IllegalStateException ignored) {
                // JVM already shutting down; the hook is a no-op now
            }
        }
    }

    private boolean shutdownInternal() {
        if (!closed.compareAndSet(false, true)) {
            return false;
        }
        running = false;
        if (flushThread != null) {
            flushThread.interrupt();
            try {
                flushThread.join(2_000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        try {
            flush();
        } finally {
            try {
                storage.close();
            } catch (Exception e) {
                System.err.println("Warning: closing persistence backend failed: " + e.getMessage());
            }
        }
        if (active == this) {
            active = null;
        }
        return true;
    }

    private void startFlushLoop() {
        flushThread = Thread.ofVirtual().name("swoft-persist-flush").start(() -> {
            while (running) {
                try {
                    Thread.sleep(flushMillis);
                } catch (InterruptedException e) {
                    return;
                }
                if (running) {
                    flush();
                }
            }
        });
    }

    private void loadAll() {
        for (PersistentDeclModel decl : declarations.values()) {
            ConcurrentHashMap<String, Object> rows = new ConcurrentHashMap<>();
            Map<String, JsonElement> stored;
            try {
                stored = storage.loadAll(decl.name());
            } catch (Exception e) {
                System.err.println("Warning: cannot load persistent '" + decl.name()
                        + "': " + e.getMessage() + " - starting from defaults");
                stored = Map.of();
            }
            for (Map.Entry<String, JsonElement> entry : stored.entrySet()) {
                Object value = coerceStoredValue(decl.type(), entry.getValue());
                if (value == null) {
                    System.err.println("Warning: bad stored value for " + decl.name()
                            + rowLabel(entry.getKey()) + ": " + entry.getValue()
                            + " (expected " + decl.type() + ") - using default");
                    continue;
                }
                rows.put(entry.getKey(), value);
            }
            cache.put(decl.name(), rows);
        }
    }

    /**
     * Defaults are constant expressions; evaluate each once with a bare
     * executor and coerce to the declared type.
     */
    private void evaluateDefaults() {
        ASTExecutor executor = new ASTExecutor(null, new HashMap<>());
        for (PersistentDeclModel decl : declarations.values()) {
            Object value;
            try {
                value = coerceRuntime(decl, executor.evaluateExpression(decl.defaultValue()));
            } catch (Exception e) {
                Object zero = zeroValue(decl.type().getBaseType());
                System.err.println("Warning: bad default for persistent '" + decl.name()
                        + "': " + e.getMessage() + " - using " + zero);
                value = zero;
            }
            defaults.put(decl.name(), value);
        }
    }

    private PersistentDeclModel requireDeclared(String name) {
        PersistentDeclModel decl = declarations.get(name);
        if (decl == null) {
            throw new ScriptError("unknown persistent variable: " + name);
        }
        return decl;
    }

    private Object coerceRuntime(PersistentDeclModel decl, Object value) {
        if (NoneValue.isNone(value)) {
            throw new ScriptError("cannot store none in persistent '" + decl.name() + "'");
        }
        switch (decl.type().getBaseType()) {
            case STRING:
                if (value instanceof String) {
                    return value;
                }
                break;
            case INTEGER:
                if (value instanceof Number number) {
                    return value instanceof Integer ? value : number.intValue();
                }
                break;
            case DOUBLE:
                if (value instanceof Number number) {
                    return number.doubleValue();
                }
                break;
            case BOOLEAN:
                if (value instanceof Boolean) {
                    return value;
                }
                break;
            case MAP:
                if (value instanceof net.swofty.runtime.MapValue map) {
                    return validateMapValues(decl, map);
                }
                break;
            default:
                break;
        }
        throw new ScriptError("persistent '" + decl.name() + "' holds " + decl.type()
                + ", cannot store: " + value);
    }

    /**
     * A persistent map<Scalar> must hold only scalar values of the declared
     * element type. Validates in place (no coercion widening) and returns the
     * same reference — the store keeps the live map, so a later persist_set
     * of the mutated map re-flushes the whole blob.
     */
    private Object validateMapValues(PersistentDeclModel decl, net.swofty.runtime.MapValue map) {
        BaseType element = mapElementType(decl.type());
        for (Map.Entry<Object, Object> entry : map.entrySet()) {
            Object v = entry.getValue();
            if (NoneValue.isNone(v) || !matchesScalar(element, v)) {
                throw new ScriptError("persistent map '" + decl.name() + "' holds "
                        + decl.type() + ", but key '" + entry.getKey()
                        + "' has incompatible value: " + v);
            }
        }
        return map;
    }

    private static boolean matchesScalar(BaseType element, Object v) {
        switch (element) {
            case STRING: return v instanceof String;
            case INTEGER: return v instanceof Number;
            case DOUBLE: return v instanceof Number;
            case BOOLEAN: return v instanceof Boolean;
            default: return false;
        }
    }

    /**
     * The VALUE type of a map. Two subtype shapes are accepted: the legacy
     * single-subtype {@code map<V>} (key implicitly String) uses subtype[0] as
     * the value; a keyed {@code map<K,V>} carries [K, V] and uses subtype[1].
     * STRING when a bare map slipped through.
     */
    private static BaseType mapElementType(net.swofty.nativebridge.representation.DataType type) {
        List<net.swofty.nativebridge.representation.DataType> subs = type.getSubTypes();
        if (subs.isEmpty()) {
            return BaseType.STRING;
        }
        return subs.size() >= 2 ? subs.get(1).getBaseType() : subs.get(0).getBaseType();
    }

    /**
     * The KEY type of a map: INTEGER for a keyed {@code map<Integer, V>}
     * ([K, V] subtypes), otherwise STRING (legacy {@code map<V>} or a bare
     * map). Determines how JSON string keys coerce back on load.
     */
    private static BaseType mapKeyType(net.swofty.nativebridge.representation.DataType type) {
        List<net.swofty.nativebridge.representation.DataType> subs = type.getSubTypes();
        return subs.size() >= 2 ? subs.get(0).getBaseType() : BaseType.STRING;
    }

    /**
     * Deserialize one stored row into a runtime value. A map<Scalar> row is a
     * whole-map JSON object (see the file docs on the map blob format); scalar
     * rows delegate to coerceStored. null = bad row (caller warns + defaults).
     */
    private static Object coerceStoredValue(
            net.swofty.nativebridge.representation.DataType type, JsonElement element) {
        if (type.getBaseType() == BaseType.MAP) {
            return mapFromJson(mapKeyType(type), mapElementType(type), element);
        }
        return coerceStored(type.getBaseType(), element);
    }

    /**
     * Parse a stored map blob (a JSON object of key -&gt; scalar) into a live
     * MapValue, coercing each value to the declared element type. A malformed
     * blob or any bad entry yields null so the caller falls back to the
     * default (an empty map). This is the read side of the whole-map JSON
     * blob format: {@code {"alice":5,"bob":3}} for a map&lt;Integer&gt;.
     */
    private static Object mapFromJson(BaseType keyType, BaseType element, JsonElement blob) {
        if (blob == null || !blob.isJsonObject()) {
            return null;
        }
        net.swofty.runtime.MapValue map = new net.swofty.runtime.MapValue();
        for (Map.Entry<String, JsonElement> entry : blob.getAsJsonObject().entrySet()) {
            Object value = coerceStored(element, entry.getValue());
            if (value == null) {
                return null;
            }
            // JSON object keys are always strings; an Integer-keyed map coerces
            // each decimal-string key back to a boxed Integer so it reloads as
            // Integer (not "1"/"2"/"3"), per the declared key type.
            Object key = coerceMapKeyType(keyType, entry.getKey());
            if (key == null) {
                return null;
            }
            map.put(key, value);
        }
        return map;
    }

    /**
     * Coerce a stored (always-String) JSON object key back to the declared map
     * key type: INTEGER parses the decimal string to a boxed Integer, STRING
     * passes through. A non-numeric key for an Integer map is a bad row (null).
     */
    private static Object coerceMapKeyType(BaseType keyType, String storedKey) {
        if (keyType == BaseType.INTEGER) {
            try {
                return Integer.valueOf(storedKey);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return storedKey;
    }

    /** null = bad row (caller warns and falls back to the default). */
    private static Object coerceStored(BaseType base, JsonElement element) {
        try {
            JsonPrimitive primitive = element.getAsJsonPrimitive();
            switch (base) {
                case STRING:
                    return primitive.getAsString();
                case INTEGER:
                    return primitive.isBoolean() ? null : (Integer) primitive.getAsInt();
                case DOUBLE:
                    return primitive.isBoolean() ? null : (Double) primitive.getAsDouble();
                case BOOLEAN:
                    return primitive.isBoolean() ? (Boolean) primitive.getAsBoolean() : null;
                default:
                    return null;
            }
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * A stored map's JSON object key. Player / offline-player keys serialize by
     * uuid string (reconnect-stable); every other key is its string form. Kept
     * in sync with {@link net.swofty.runtime.Values#coerceMapKey}, which hashes
     * the live map's keys the same way at insertion time.
     */
    private static String mapKeyToJsonKey(Object key) {
        if (key instanceof net.minestom.server.entity.Player player) {
            return player.getUuid().toString();
        }
        if (key instanceof net.swofty.players.OfflinePlayerValue offline) {
            return offline.uuid();
        }
        return String.valueOf(key);
    }

    private static JsonElement toJson(Object value) {
        if (value instanceof Boolean bool) {
            return new JsonPrimitive(bool);
        }
        if (value instanceof Number number) {
            return new JsonPrimitive(number);
        }
        // whole-map blob: a persistent map<Scalar> serializes to a single
        // JSON object under its row key, coherent with the scalar rows around
        // it (SQL/Mongo backends store it as the row's JSON text; the files
        // backend nests it inside the var's JSON document)
        if (value instanceof net.swofty.runtime.MapValue map) {
            com.google.gson.JsonObject object = new com.google.gson.JsonObject();
            // snapshot(): the flush thread must not iterate the live cached
            // map while a script thread mutates it via map_set/map_delete -
            // that raced into ConcurrentModificationException and killed the
            // flush loop. The copy is taken under the map's own monitor.
            for (Map.Entry<Object, Object> entry : map.snapshot().entrySet()) {
                // JSON object keys must be strings; an Integer key serializes as
                // its decimal string and coerces back to Integer on load. A
                // Player-keyed map (map<Player, V>) serializes by uuid so the
                // stored row is reconnect-stable — keys already hash by uuid at
                // insertion (Values.coerceMapKey), so this only guards a raw
                // Player object that reached the map without going through it.
                object.add(mapKeyToJsonKey(entry.getKey()), toJson(entry.getValue()));
            }
            return object;
        }
        return new JsonPrimitive(String.valueOf(value));
    }

    private static Object zeroValue(BaseType base) {
        switch (base) {
            case INTEGER: return 0;
            case DOUBLE: return 0.0;
            case BOOLEAN: return false;
            case MAP: return new net.swofty.runtime.MapValue();
            default: return "";
        }
    }

    private static boolean isScalar(BaseType base) {
        return base == BaseType.STRING || base == BaseType.INTEGER
                || base == BaseType.DOUBLE || base == BaseType.BOOLEAN;
    }

    /**
     * A persistent may hold a scalar or a map of scalars. map&lt;Scalar&gt;
     * serializes as a whole-map JSON blob per row (design phase-10 §1); nested
     * maps and maps of non-scalars are not persistable.
     */
    private static boolean isPersistable(
            net.swofty.nativebridge.representation.DataType type) {
        BaseType base = type.getBaseType();
        if (isScalar(base)) {
            return true;
        }
        return base == BaseType.MAP && isScalar(mapElementType(type));
    }

    private static String rowLabel(String key) {
        return key.isEmpty() ? "" : "[" + key + "]";
    }

    /**
     * Shared row-parsing helper for the SQL/Mongo backends, which store
     * scalar values as JSON text; unparseable text is kept as a plain
     * string so type coercion decides its fate.
     */
    static void putParsedRow(Map<String, JsonElement> rows, String var, String key, String raw) {
        if (key == null || raw == null) {
            System.err.println("Warning: null row for persistent '" + var + "' - skipping");
            return;
        }
        try {
            rows.put(key, JsonParser.parseString(raw));
        } catch (Exception e) {
            rows.put(key, new JsonPrimitive(raw));
        }
    }
}
