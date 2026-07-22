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
import net.swofty.model.StructDefModel;
import net.swofty.model.StructFieldModel;
import net.swofty.nativebridge.representation.BaseType;
import net.swofty.nativebridge.representation.DataType;
import net.swofty.props.NoneValue;
import net.swofty.structs.StructRegistry;
import net.swofty.structs.StructValue;

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
        // a struct is likewise a mutable reference: hand absent rows a fresh
        // shallow copy so a caller mutating a field can't corrupt the shared
        // default (and thus every other absent subject)
        if (def instanceof StructValue struct) {
            return struct.copy();
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
        // §4.2: a write to a persistent root can add or remove a reactive struct
        // instance from the live set — re-derive the liveness index. No-op (a
        // cheap flag check) when no struct declares a reactive field.
        net.swofty.structs.InstanceReceiverRuntime.rebuild();
    }

    /** Visitor over one cached persistent row: its variable name, storage key, value. */
    @FunctionalInterface
    public interface RowVisitor {
        void visit(String var, String key, Object value);
    }

    /**
     * Visit every row currently cached across all persistent variables — the
     * persistent roots the instance-receiver runtime walks to derive liveness
     * (§4.2). The (var, key) pair is the row's provenance: a reactive struct
     * instance found while walking a row belongs to that row, so a mutation to
     * the instance inside a handler can re-dirty exactly that row (see
     * {@link #markDirty}) to make it durable. Iterates a snapshot of the row
     * references, so a concurrent write never breaks the walk.
     */
    public void forEachCachedRow(RowVisitor visitor) {
        for (Map.Entry<String, ConcurrentHashMap<String, Object>> var : cache.entrySet()) {
            for (Map.Entry<String, Object> row
                    : new java.util.ArrayList<>(var.getValue().entrySet())) {
                visitor.visit(var.getKey(), row.getKey(), row.getValue());
            }
        }
    }

    /**
     * Mark an already-cached row dirty so the next flush re-serializes it, WITHOUT
     * re-coercing or re-storing the value (it is mutated in place). Used by the
     * instance-receiver runtime (§4.2): a reactive handler mutates a struct field
     * of a persistent-rooted instance in place (e.g. {@code set score at b to N}),
     * which is visible in memory but never dirties the owning row on its own — so
     * the mutation would be lost on the next reload. Re-dirtying the row here makes
     * the "durable stateful actor" durable. No-op for an unknown/undeclared var.
     */
    public void markDirty(String name, String key) {
        if (name == null || key == null) {
            return;
        }
        PersistentDeclModel decl = declarations.get(name);
        if (decl == null) {
            return;
        }
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
        // an optional<T> persistent legitimately holds none (its declared
        // default): none stays the none sentinel (serializes to JSON null),
        // and a present value coerces against the inner leaf type T. The
        // typechecker only permits optional of a leaf value type, so the
        // inner is always a scalar / Location / Vec / Item.
        if (decl.type().getBaseType() == BaseType.OPTIONAL) {
            if (NoneValue.isNone(value)) {
                return NoneValue.INSTANCE;
            }
            net.swofty.nativebridge.representation.DataType inner = listElementType(decl.type());
            BaseType innerBase = inner != null ? inner.getBaseType() : BaseType.UNKNOWN;
            Object coerced = coerceLeaf(innerBase, value);
            if (coerced != null) {
                return coerced;
            }
            throw new ScriptError("persistent '" + decl.name() + "' holds " + decl.type()
                    + ", cannot store: " + value);
        }
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
            case LOCATION:
                if (value instanceof net.minestom.server.coordinate.Pos) {
                    return value;
                }
                break;
            case VEC:
                if (value instanceof net.minestom.server.coordinate.Vec) {
                    return value;
                }
                if (value instanceof net.minestom.server.coordinate.Pos pos) {
                    return new net.minestom.server.coordinate.Vec(pos.x(), pos.y(), pos.z());
                }
                break;
            case ITEM:
                if (value instanceof net.minestom.server.item.ItemStack) {
                    return value;
                }
                break;
            case PLAYER:
                // a Player value persists by uuid; keep the live reference here
                // (serialization to uuid happens at flush, see toJson)
                if (value instanceof net.minestom.server.entity.Player) {
                    return value;
                }
                break;
            case STRUCT:
                // a struct persists as a JSON object of its fields; keep the
                // live StructValue reference so a later persist_set of the
                // mutated instance re-flushes the whole blob (map/list semantics)
                if (value instanceof StructValue struct
                        && struct.typeName().equals(decl.type().getTypeName())) {
                    return value;
                }
                break;
            case LIST:
                if (value instanceof List<?> list) {
                    return validateListValues(decl, list);
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
            if (NoneValue.isNone(v) || !matchesLeaf(element, v)) {
                throw new ScriptError("persistent map '" + decl.name() + "' holds "
                        + decl.type() + ", but key '" + entry.getKey()
                        + "' has incompatible value: " + v);
            }
        }
        return map;
    }

    /**
     * A persistent {@code list<T>} must hold only values of the declared leaf
     * element type T (scalar / Location / Vec / Item). Validates in place (no
     * widening) and returns the same live reference, so a later persist_set of
     * the mutated list re-flushes the whole JSON array — matching map semantics.
     */
    private Object validateListValues(PersistentDeclModel decl, List<?> list) {
        net.swofty.nativebridge.representation.DataType elemType =
                listElementType(decl.type());
        BaseType element = elemType != null ? elemType.getBaseType() : BaseType.UNKNOWN;
        for (Object v : list) {
            if (NoneValue.isNone(v) || !matchesLeaf(element, v)) {
                throw new ScriptError("persistent list '" + decl.name() + "' holds "
                        + decl.type() + ", but an element has incompatible value: " + v);
            }
        }
        return list;
    }

    /**
     * Runtime type check for a persistable leaf element: the four scalars plus
     * the rich value types Location (Pos), Vec, and Item (ItemStack). Numbers
     * are accepted for INTEGER/DOUBLE without widening (kept as the caller's
     * boxed type), mirroring the scalar-map validation this replaced.
     */
    /**
     * Coerce a runtime value to a persistable leaf type, or null if it does not
     * match. Mirrors the leaf cases of {@link #coerceRuntime}: Numbers narrow to
     * Integer / widen to Double without changing the caller's other types, and a
     * Pos is accepted as a Vec (its position drops orientation). Used by the
     * optional&lt;T&gt; store path so a present optional value coerces exactly
     * like a bare T persistent.
     */
    private static Object coerceLeaf(BaseType base, Object value) {
        switch (base) {
            case STRING:
                return value instanceof String ? value : null;
            case INTEGER:
                return value instanceof Number n ? (value instanceof Integer ? value : n.intValue()) : null;
            case DOUBLE:
                return value instanceof Number n ? n.doubleValue() : null;
            case BOOLEAN:
                return value instanceof Boolean ? value : null;
            case LOCATION:
                return value instanceof net.minestom.server.coordinate.Pos ? value : null;
            case VEC:
                if (value instanceof net.minestom.server.coordinate.Vec) {
                    return value;
                }
                if (value instanceof net.minestom.server.coordinate.Pos pos) {
                    return new net.minestom.server.coordinate.Vec(pos.x(), pos.y(), pos.z());
                }
                return null;
            case ITEM:
                return value instanceof net.minestom.server.item.ItemStack ? value : null;
            case PLAYER:
                return value instanceof net.minestom.server.entity.Player ? value : null;
            default:
                return null;
        }
    }

    private static boolean matchesLeaf(BaseType element, Object v) {
        switch (element) {
            case STRING: return v instanceof String;
            case INTEGER: return v instanceof Number;
            case DOUBLE: return v instanceof Number;
            case BOOLEAN: return v instanceof Boolean;
            case LOCATION: return v instanceof net.minestom.server.coordinate.Pos;
            case VEC: return v instanceof net.minestom.server.coordinate.Vec;
            case ITEM: return v instanceof net.minestom.server.item.ItemStack;
            case PLAYER: return v instanceof net.minestom.server.entity.Player;
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
     * The full VALUE {@link net.swofty.nativebridge.representation.DataType} of a
     * map (not just its base): {@code map<K, V>} carries [K, V] and yields V;
     * legacy {@code map<V>} carries [V]. null for a bare map. Needed so a
     * map&lt;String, Location&gt; deserializes each value by its structured type.
     */
    private static net.swofty.nativebridge.representation.DataType mapValueType(
            net.swofty.nativebridge.representation.DataType type) {
        List<net.swofty.nativebridge.representation.DataType> subs = type.getSubTypes();
        if (subs.isEmpty()) {
            return null;
        }
        return subs.size() >= 2 ? subs.get(1) : subs.get(0);
    }

    /**
     * The element {@link net.swofty.nativebridge.representation.DataType} of a
     * {@code list<T>} (subtype[0]); null for a bare {@code list}.
     */
    private static net.swofty.nativebridge.representation.DataType listElementType(
            net.swofty.nativebridge.representation.DataType type) {
        List<net.swofty.nativebridge.representation.DataType> subs = type.getSubTypes();
        return subs.isEmpty() ? null : subs.get(0);
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
        switch (type.getBaseType()) {
            case STRING:
            case INTEGER:
            case DOUBLE:
            case BOOLEAN:
                return coerceStored(type.getBaseType(), element);
            case LOCATION:
                return locationFromJson(element);
            case VEC:
                return vecFromJson(element);
            case ITEM:
                return itemFromJson(element);
            case PLAYER:
                return playerFromJson(element);
            case STRUCT:
                return structFromJson(type, element);
            case LIST:
                return listFromJson(listElementType(type), element);
            case MAP:
                return mapFromJson(mapKeyType(type), mapValueType(type), element);
            case OPTIONAL:
                // a persisted optional is either JSON null (none) or the inner
                // leaf serialization; null-in-JSON reloads as the none sentinel
                if (element == null || element.isJsonNull()) {
                    return NoneValue.INSTANCE;
                }
                net.swofty.nativebridge.representation.DataType inner = listElementType(type);
                return inner == null ? null : coerceStoredValue(inner, element);
            default:
                return null;
        }
    }

    /**
     * Deserialize a stored Location blob {@code {x,y,z,yaw,pitch,world}} into a
     * Pos. The optional world name is informational: a script Location is a bare
     * Pos with no attached instance, so a present name is resolved lazily by the
     * teleport/spawn sites via InstanceRegistry — a world missing at load simply
     * keeps the coordinates. Missing x/y/z or a non-object blob is a bad row.
     */
    private static Object locationFromJson(JsonElement blob) {
        if (blob == null || !blob.isJsonObject()) {
            return null;
        }
        com.google.gson.JsonObject object = blob.getAsJsonObject();
        try {
            double x = object.get("x").getAsDouble();
            double y = object.get("y").getAsDouble();
            double z = object.get("z").getAsDouble();
            float yaw = object.has("yaw") ? object.get("yaw").getAsFloat() : 0f;
            float pitch = object.has("pitch") ? object.get("pitch").getAsFloat() : 0f;
            return new net.minestom.server.coordinate.Pos(x, y, z, yaw, pitch);
        } catch (Exception e) {
            return null;
        }
    }

    /** Deserialize a stored Vec blob {@code {x,y,z}}; bad/partial blob = null. */
    private static Object vecFromJson(JsonElement blob) {
        if (blob == null || !blob.isJsonObject()) {
            return null;
        }
        com.google.gson.JsonObject object = blob.getAsJsonObject();
        try {
            return new net.minestom.server.coordinate.Vec(
                    object.get("x").getAsDouble(),
                    object.get("y").getAsDouble(),
                    object.get("z").getAsDouble());
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Deserialize a stored Item (an SNBT string via to_nbt/from_nbt) back into an
     * ItemStack. Malformed SNBT, a non-string blob, or a payload that is not a
     * valid item all yield null so the caller falls back to the default + warns.
     */
    private static Object itemFromJson(JsonElement blob) {
        if (blob == null || !blob.isJsonPrimitive()) {
            return null;
        }
        try {
            net.kyori.adventure.nbt.CompoundBinaryTag compound =
                    net.kyori.adventure.nbt.TagStringIO.tagStringIO()
                            .asCompound(blob.getAsString());
            return net.minestom.server.item.ItemStack.fromItemNBT(compound);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Resolve a stored Player (a uuid string) back to the live online Player,
     * or null (resolve-or-cull, §3.2): a player who is offline at load can't be
     * re-resolved, so the row is treated as bad and falls back to the default +
     * warn. A non-string or unparseable blob is likewise a bad row.
     */
    private static Object playerFromJson(JsonElement blob) {
        if (blob == null || !blob.isJsonPrimitive()) {
            return null;
        }
        try {
            java.util.UUID uuid = java.util.UUID.fromString(blob.getAsString());
            return net.minestom.server.MinecraftServer.getConnectionManager()
                    .getOnlinePlayerByUuid(uuid);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Deserialize a stored struct blob (a JSON object of its fields, §3.2) into a
     * live {@link StructValue}, dispatching each field by its declared type
     * (nested structs, list/map/optional, Location/Vec/Item/Player-uuid, scalars).
     * A missing/null field is only valid for an optional field (reloads as none);
     * any missing required field, an unknown struct type, a non-object blob, or a
     * bad field value makes the whole row bad (null) so the caller falls back to
     * the default + warn.
     */
    private static Object structFromJson(DataType type, JsonElement blob) {
        if (blob == null || !blob.isJsonObject()) {
            return null;
        }
        StructDefModel def = StructRegistry.get(type.getTypeName());
        if (def == null) {
            return null;
        }
        com.google.gson.JsonObject object = blob.getAsJsonObject();
        LinkedHashMap<String, Object> values = new LinkedHashMap<>();
        for (StructFieldModel field : def.fields()) {
            JsonElement element = object.get(field.name());
            Object value;
            if (element == null || element.isJsonNull()) {
                if (field.type().getBaseType() == BaseType.OPTIONAL) {
                    value = NoneValue.INSTANCE;
                } else {
                    return null;
                }
            } else {
                value = coerceStoredValue(field.type(), element);
                if (value == null) {
                    return null;
                }
            }
            values.put(field.name(), value);
        }
        return new StructValue(def.name(), values);
    }

    /**
     * Serialize a struct instance to a JSON object of its fields, in declaration
     * order (§3.2). Each field is dispatched by its runtime value type via
     * {@link #toJson} — so nested structs recurse, Players emit their uuid, and
     * Location/Vec/Item/list/map/optional reuse the rich-persistence encodings.
     */
    private static JsonElement structToJson(StructValue struct) {
        com.google.gson.JsonObject object = new com.google.gson.JsonObject();
        StructDefModel def = StructRegistry.get(struct.typeName());
        if (def == null) {
            // unknown struct type (registry cleared / never declared): emit the
            // raw field map so no data is silently dropped
            for (Map.Entry<String, Object> entry : struct.fields().entrySet()) {
                object.add(entry.getKey(), toJson(entry.getValue()));
            }
            return object;
        }
        for (StructFieldModel field : def.fields()) {
            object.add(field.name(), toJson(struct.getField(field.name())));
        }
        return object;
    }

    /**
     * Deserialize a stored {@code list<T>} JSON array into a live ArrayList,
     * deserializing each element by the declared element type. A non-array blob,
     * an unknown element type, or any bad element makes the whole row bad (null),
     * so the caller falls back to the default (an empty list) + warn.
     */
    private static Object listFromJson(
            net.swofty.nativebridge.representation.DataType elementType, JsonElement blob) {
        if (blob == null || !blob.isJsonArray() || elementType == null) {
            return null;
        }
        List<Object> out = new java.util.ArrayList<>();
        for (JsonElement element : blob.getAsJsonArray()) {
            Object value = coerceStoredValue(elementType, element);
            if (value == null) {
                return null;
            }
            out.add(value);
        }
        return out;
    }

    /**
     * Parse a stored map blob (a JSON object of key -&gt; scalar) into a live
     * MapValue, coercing each value to the declared element type. A malformed
     * blob or any bad entry yields null so the caller falls back to the
     * default (an empty map). This is the read side of the whole-map JSON
     * blob format: {@code {"alice":5,"bob":3}} for a map&lt;Integer&gt;.
     */
    private static Object mapFromJson(BaseType keyType,
            net.swofty.nativebridge.representation.DataType valueType, JsonElement blob) {
        if (blob == null || !blob.isJsonObject() || valueType == null) {
            return null;
        }
        net.swofty.runtime.MapValue map = new net.swofty.runtime.MapValue();
        for (Map.Entry<String, JsonElement> entry : blob.getAsJsonObject().entrySet()) {
            Object value = coerceStoredValue(valueType, entry.getValue());
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
        // an optional persistent explicitly set to none serializes as JSON null
        // and reloads as the none sentinel (coerceStoredValue OPTIONAL branch)
        if (NoneValue.isNone(value)) {
            return com.google.gson.JsonNull.INSTANCE;
        }
        if (value instanceof Boolean bool) {
            return new JsonPrimitive(bool);
        }
        if (value instanceof Number number) {
            return new JsonPrimitive(number);
        }
        // Player -> uuid string (reconnect-stable; resolve-or-cull on load).
        if (value instanceof net.minestom.server.entity.Player player) {
            return new JsonPrimitive(player.getUuid().toString());
        }
        // struct -> JSON object of its fields (§3.2), each field dispatched by
        // its declared type. Placed before the generic Map branch: a StructValue
        // is not a Map, but keep the ordering explicit.
        if (value instanceof StructValue struct) {
            return structToJson(struct);
        }
        // Location -> {x,y,z,yaw,pitch}. A script Location is a bare Pos with no
        // attached world, so no "world" field is emitted (see locationFromJson:
        // world is a lazy-resolve hint, not part of the value); load reads back
        // the coordinates + orientation.
        if (value instanceof net.minestom.server.coordinate.Pos pos) {
            com.google.gson.JsonObject object = new com.google.gson.JsonObject();
            object.addProperty("x", pos.x());
            object.addProperty("y", pos.y());
            object.addProperty("z", pos.z());
            object.addProperty("yaw", pos.yaw());
            object.addProperty("pitch", pos.pitch());
            return object;
        }
        // Vec -> {x,y,z} (velocity/offset value; no orientation).
        if (value instanceof net.minestom.server.coordinate.Vec vec) {
            com.google.gson.JsonObject object = new com.google.gson.JsonObject();
            object.addProperty("x", vec.x());
            object.addProperty("y", vec.y());
            object.addProperty("z", vec.z());
            return object;
        }
        // Item -> SNBT string, symmetric with the to_nbt/from_nbt builtins
        // (ItemStack.toItemNBT + TagStringIO); itemFromJson parses it back.
        if (value instanceof net.minestom.server.item.ItemStack stack) {
            try {
                return new JsonPrimitive(net.kyori.adventure.nbt.TagStringIO.tagStringIO()
                        .asString(stack.toItemNBT()));
            } catch (java.io.IOException e) {
                // in-memory SNBT write should not fail; surface as unchecked so
                // flush() keeps the row dirty and retries rather than dropping it
                throw new java.io.UncheckedIOException(e);
            }
        }
        // list<T> -> JSON array of the element serialization. Iterated as a
        // defensive copy: the live cached list can be mutated by a script thread
        // (list_add/remove) while the flush thread serializes it, and a raw
        // iteration would risk ConcurrentModificationException.
        if (value instanceof List<?> list) {
            com.google.gson.JsonArray array = new com.google.gson.JsonArray();
            for (Object element : new java.util.ArrayList<>(list)) {
                if (!NoneValue.isNone(element)) {
                    array.add(toJson(element));
                }
            }
            return array;
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
            case LIST: return new java.util.ArrayList<>();
            case LOCATION: return new net.minestom.server.coordinate.Pos(0, 0, 0);
            case VEC: return net.minestom.server.coordinate.Vec.ZERO;
            case ITEM: return net.minestom.server.item.ItemStack.AIR;
            // an optional persistent's absent/failed default is none, not ""
            case OPTIONAL: return NoneValue.INSTANCE;
            default: return "";
        }
    }

    private static boolean isScalar(BaseType base) {
        return base == BaseType.STRING || base == BaseType.INTEGER
                || base == BaseType.DOUBLE || base == BaseType.BOOLEAN;
    }

    /**
     * A persistable LEAF value type: the four scalars plus the rich value types
     * Location, Vec, and Item. These all have a clean JSON serialization and are
     * the only types allowed as the element of a persistent list/map.
     */
    private static boolean isLeafPersistable(
            net.swofty.nativebridge.representation.DataType type) {
        BaseType base = type.getBaseType();
        return isScalar(base) || base == BaseType.LOCATION
                || base == BaseType.VEC || base == BaseType.ITEM
                || base == BaseType.PLAYER;
    }

    /**
     * A persistent may hold a leaf value (scalar / Location / Vec / Item) or a
     * one-level list/map of those leaves. list&lt;T&gt; serializes as a JSON
     * array and map&lt;K, T&gt; as a whole-map JSON object per row; nested
     * lists/maps and collections of non-leaf types are not persistable.
     */
    private static boolean isPersistable(
            net.swofty.nativebridge.representation.DataType type) {
        BaseType base = type.getBaseType();
        if (isLeafPersistable(type)) {
            return true;
        }
        if (base == BaseType.LIST) {
            net.swofty.nativebridge.representation.DataType element = listElementType(type);
            return element != null && isLeafPersistable(element);
        }
        if (base == BaseType.MAP) {
            net.swofty.nativebridge.representation.DataType value = mapValueType(type);
            return value != null && isLeafPersistable(value);
        }
        // optional<T> persists exactly like T (present) or JSON null (none);
        // the typechecker only allows a leaf T inside the optional
        if (base == BaseType.OPTIONAL) {
            net.swofty.nativebridge.representation.DataType inner = listElementType(type);
            return inner != null && isLeafPersistable(inner);
        }
        // a struct persists (§3.2) iff every one of its fields is persistable;
        // struct fields may themselves be leaves, nested structs, or
        // list/map/optional of those (richer than a top-level persistent, whose
        // collection elements must be leaves)
        if (base == BaseType.STRUCT) {
            return isStructPersistable(type, new java.util.HashSet<>());
        }
        return false;
    }

    /**
     * A struct is persistable when it is declared and every field type is
     * field-persistable. The visiting set guards against a cyclic struct
     * declaration recursing forever (a cycle is optimistically treated as OK;
     * the typechecker rejects genuinely infinite value structs).
     */
    private static boolean isStructPersistable(DataType type, Set<String> visiting) {
        String name = type.getTypeName();
        if (name == null || !visiting.add(name)) {
            return name != null; // already visiting == cycle == accept
        }
        try {
            StructDefModel def = StructRegistry.get(name);
            if (def == null) {
                return false;
            }
            for (StructFieldModel field : def.fields()) {
                if (!isFieldPersistable(field.type(), visiting)) {
                    return false;
                }
            }
            return true;
        } finally {
            visiting.remove(name);
        }
    }

    /**
     * A struct field type is persistable when it is a leaf (scalar / Location /
     * Vec / Item / Player-uuid), a nested persistable struct, or a
     * list/map/optional whose element is itself field-persistable.
     */
    private static boolean isFieldPersistable(DataType type, Set<String> visiting) {
        BaseType base = type.getBaseType();
        if (isLeafPersistable(type)) {
            return true;
        }
        if (base == BaseType.STRUCT) {
            return isStructPersistable(type, visiting);
        }
        if (base == BaseType.LIST) {
            DataType element = listElementType(type);
            return element != null && isFieldPersistable(element, visiting);
        }
        if (base == BaseType.MAP) {
            DataType value = mapValueType(type);
            return value != null && isFieldPersistable(value, visiting);
        }
        if (base == BaseType.OPTIONAL) {
            DataType inner = listElementType(type);
            return inner != null && isFieldPersistable(inner, visiting);
        }
        return false;
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
