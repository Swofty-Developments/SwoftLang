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
import net.swofty.persist.network.AtomicOp;
import net.swofty.persist.network.LeaseManager;
import net.swofty.persist.network.NetMessage;
import net.swofty.persist.network.NetworkRuntime;
import net.swofty.persist.network.PersistMode;
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
 *
 * <p><b>Topology (design 1.10.0 §1/§2).</b> The storage block's {@code mode:}
 * selects between two behaviours, and declarations plus script code are
 * byte-identical in both:
 * <ul>
 *   <li>{@link PersistMode#STANDALONE} — the default, and everything described
 *       above, unchanged in every respect from before 1.10.0. Every network
 *       branch in this class is guarded by the mode flag, no network object is
 *       allocated, and the stored sidecars for an unchanged program are
 *       identical.</li>
 *   <li>{@link PersistMode#NETWORK} — per-player values become <em>session
 *       owned</em>: acquired + loaded before join handlers run, flushed
 *       synchronously and evicted on quit, with the lease released afterwards
 *       (§2.1). Global values become <em>replicated</em>: loaded eagerly at
 *       boot, read synchronously off the local replica, written by atomic ops
 *       applied at the backend and broadcast to the other servers (§2.2). The
 *       {@code flush:} timer is demoted to a crash checkpoint and is explicitly
 *       NOT the handoff mechanism (§2.1.4).</li>
 * </ul>
 */
public final class PersistStore {
    private static volatile PersistStore active;

    /** De-duplicates the network-mode "read of a row this server does not own" warning. */
    private static final Set<String> unownedWarned = ConcurrentHashMap.newKeySet();

    /**
     * Serialized-struct field carrying the schema version the blob was written
     * under (Tier-2 migration). Uses the reserved {@code __} prefix, which the
     * checker forbids as a struct field name, so it can never collide with a
     * real field.
     */
    private static final String SCHEMA_FIELD = "__schema";

    /** De-duplicates schema-drift warnings per (struct, field, reason). */
    private static final Set<String> driftWarned = ConcurrentHashMap.newKeySet();

    /** Lazily-built bare executor for struct-field default expressions on load. */
    private static volatile ASTExecutor healExecutor;

    private final Map<String, PersistentDeclModel> declarations = new LinkedHashMap<>();
    private final Map<String, Object> defaults = new HashMap<>();
    private final SwoftStorage storage;
    private final long flushMillis;
    private final PersistMode mode;
    private final StorageConfigModel config;
    private final ConcurrentHashMap<String, ConcurrentHashMap<String, Object>> cache =
            new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Set<String>> dirty = new ConcurrentHashMap<>();
    private final AtomicBoolean closed = new AtomicBoolean(false);
    private volatile boolean running = true;
    private Thread flushThread;
    private Thread shutdownHook;

    /** Non-null only in {@link PersistMode#NETWORK}. */
    private volatile NetworkRuntime network;

    private PersistStore(List<PersistentDeclModel> decls, SwoftStorage storage, long flushMillis,
            StorageConfigModel config) {
        this.storage = storage;
        this.flushMillis = flushMillis;
        this.config = config;
        this.mode = PersistMode.of(config);
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

        PersistStore store = new PersistStore(decls, storage, flushMillis, effective);
        store.evaluateDefaults();
        store.loadAll();
        store.startFlushLoop();
        store.shutdownHook = new Thread(store::shutdownInternal, "swoft-persist-shutdown");
        Runtime.getRuntime().addShutdownHook(store.shutdownHook);
        active = store;
        System.out.println("PersistStore: " + store.declarations.size()
                + " persistent variable(s) on backend '" + effective.backend().kind()
                + "', flush every " + effective.flushTicks() + " tick(s)"
                + (store.mode.isNetwork() ? " (crash checkpoint only)" : ""));
        // network topology is wired AFTER the eager global load so the replica is
        // already coherent before the first broadcast can arrive (§2.2/§2.3)
        if (store.mode.isNetwork()) {
            store.network = NetworkRuntime.start(store, effective, storage);
            registerReloadHook();
        }
        return store;
    }

    /**
     * Build a store that is NOT the process-wide {@link #active} one, on a
     * caller-supplied backend and with a caller-supplied server identity.
     *
     * <p>This exists for the two-server harness, which has to run two complete
     * engines against one shared backend inside a single JVM — impossible
     * through {@link #initialize}, whose singleton and JVM-wide
     * {@link net.swofty.persist.network.ServerIdentity} both assume one server
     * per process. Everything else is the same code path: the same defaults
     * evaluation, the same eager global load, the same flush loop, the same
     * {@link NetworkRuntime}. No shutdown hook is registered (the caller owns
     * the lifetime) and {@link #active} is left alone.
     */
    public static PersistStore createIsolated(List<PersistentDeclModel> decls,
            StorageConfigModel config, SwoftStorage storage, String serverId) {
        StorageConfigModel effective = config != null ? config : StorageConfigModel.defaults();
        long flushMillis = Math.max(1, effective.flushTicks()) * 50L;
        PersistStore store = new PersistStore(decls, storage, flushMillis, effective);
        store.evaluateDefaults();
        store.loadAll();
        store.startFlushLoop();
        if (store.mode.isNetwork()) {
            store.network = NetworkRuntime.start(store, effective, storage, serverId);
        }
        return store;
    }

    /** The network runtime, or null outside {@code mode: network}. */
    public NetworkRuntime network() {
        return network;
    }

    /**
     * Point the process-wide {@link #active} store at {@code store} and return
     * whatever it was pointing at. Companion to {@link #createIsolated}: script
     * execution resolves its store through {@link #active}, so running a block
     * "on server A" in the two-server harness means making A active for the
     * duration. Never used outside a harness — production has one store, set
     * once by {@link #initialize}.
     */
    public static PersistStore swapActive(PersistStore store) {
        PersistStore previous = active;
        active = store;
        return previous;
    }

    /**
     * Re-arm the hot-reload hook (§6). {@link net.swofty.reload.ReloadRegistry}
     * clears every hook after a teardown, and persistence is deliberately NOT
     * re-initialized by a reload, so the engine's re-registration pass calls this
     * to put the hook back. A no-op outside network mode.
     *
     * <p>The hook renews the leases of still-connected players — it must never
     * release them, and it must not tear the replica subscription down, because
     * nothing would rebuild either afterwards.
     */
    public static void registerReloadHook() {
        PersistStore store = active;
        if (store == null || store.network == null) {
            return;
        }
        if (net.swofty.reload.ReloadRegistry.names().contains("persist-network")) {
            // startup registers persistence and then runs register(); both call
            // this, and a duplicated hook would renew every lease twice
            return;
        }
        NetworkRuntime runtime = store.network;
        net.swofty.reload.ReloadRegistry.register("persist-network", runtime::onReload);
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
        if (mode.isNetwork()) {
            warnUnownedRead(decl, key);
        }
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
        if (mode.isNetwork() && network != null) {
            if (isSessionScoped(decl)) {
                // §2.1: exactly one owner at a time. A write against a player
                // this server does not own is the clobber the whole design
                // exists to prevent - refuse it rather than let it reach the
                // backend behind the real owner's back.
                if (!network.leases().holds(key)) {
                    System.err.println("[persist] refusing to write '" + decl.name()
                            + rowLabel(key) + "': this server does not own that"
                            + " session (use an atomic op to reach a remote player)");
                    return;
                }
            } else {
                // §2.2/§3.2: a global write is an unconditional atomic set -
                // applied at the backend, then broadcast (last-writer-wins).
                network.replica().applyLocal(decl.name(), key, AtomicOp.SET, coerced, null);
                net.swofty.structs.InstanceReceiverRuntime.rebuild();
                return;
            }
        }
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

    // ---------------------------------------------------------------------
    // Network topology (design 1.10.0 §2/§6). Everything below is inert in
    // mode: standalone - the methods are either mode-gated no-ops or are only
    // ever called from the network runtime.
    // ---------------------------------------------------------------------

    /** The configured topology. */
    public PersistMode mode() {
        return mode;
    }

    /** Whether this store runs the multi-server topology. */
    public boolean isNetwork() {
        return mode.isNetwork();
    }

    /** The storage block this store was built from. */
    public StorageConfigModel config() {
        return config;
    }

    /** The backend, for the network runtime's direct row IO. */
    public SwoftStorage backend() {
        return storage;
    }

    /** Whether {@code name} is a persistent variable of this program. */
    public boolean isDeclared(String name) {
        return declarations.containsKey(name);
    }

    /**
     * §2: strategy is chosen by DECL SHAPE. {@code X for Player} /
     * {@code for OfflinePlayer} is session-owned (one server at a time); every
     * other shape — a bare global, or one keyed by Integer/String — is a
     * replicated global owned by nobody.
     */
    public boolean isSessionScoped(String name) {
        return isSessionScoped(declarations.get(name));
    }

    private static boolean isSessionScoped(PersistentDeclModel decl) {
        if (decl == null || decl.subject() == null) {
            return false;
        }
        BaseType subject = decl.subject().getBaseType();
        return subject == BaseType.PLAYER || subject == BaseType.OFFLINE_PLAYER;
    }

    /**
     * §2.1.1: acquire-then-load. Reads this subject's row of every
     * session-owned variable straight off the backend (no cache, no staleness)
     * and stamps each row with the lease generation, so a flush from the
     * previous owner is rejected as stale.
     *
     * <p>Throws on backend failure: the caller must then refuse the join rather
     * than let the player in on defaults.
     */
    public void loadSession(String key, long generation) {
        if (!mode.isNetwork()) {
            return;
        }
        NetworkRuntime runtime = network;
        for (PersistentDeclModel decl : declarations.values()) {
            if (!isSessionScoped(decl)) {
                continue;
            }
            JsonElement stored = storage.load(decl.name(), key);
            ConcurrentHashMap<String, Object> rows =
                    cache.computeIfAbsent(decl.name(), k -> new ConcurrentHashMap<>());
            Object value = stored == null ? null : coerceStoredValue(decl.type(), stored);
            if (stored != null && value == null) {
                System.err.println("Warning: bad stored value for " + decl.name()
                        + rowLabel(key) + ": " + stored + " (expected " + decl.type()
                        + ") - using default");
            }
            if (value == null) {
                // absent row: get() resolves to the declared default, which is
                // the correct answer for a subject who has never been stored
                rows.remove(key);
            } else {
                rows.put(key, value);
            }
            // a marker left over from a previous session of this subject would
            // re-write a row we have just re-read
            Set<String> markers = dirty.get(decl.name());
            if (markers != null) {
                markers.remove(key);
            }
            if (runtime != null) {
                runtime.versions().stamp(decl.name(), key, generation);
            }
        }
    }

    /**
     * §2.1.2: the SYNCHRONOUS save half of save-and-evict. Writes this subject's
     * dirty session rows immediately — not on the next timer tick, because the
     * next server may load them a millisecond from now.
     *
     * <p>Refuses the whole flush when the lease is no longer ours at the
     * generation we took it at (§2.1.3, stale version = late writer loses).
     */
    public synchronized void flushSession(String key) {
        if (!mode.isNetwork()) {
            return;
        }
        NetworkRuntime runtime = network;
        long generation = runtime != null
                ? runtime.leases().generation(key) : LeaseManager.NO_LEASE;
        if (runtime != null && !stillOwnsSession(key)) {
            System.err.println("[persist] REJECTED the session flush for " + key
                    + ": this server no longer holds the lease at generation "
                    + generation + " - another server owns this session now and"
                    + " writing would clobber it");
            return;
        }
        for (PersistentDeclModel decl : declarations.values()) {
            if (!isSessionScoped(decl)) {
                continue;
            }
            Set<String> markers = dirty.get(decl.name());
            if (markers == null || !markers.remove(key)) {
                continue;
            }
            if (runtime != null && !runtime.versions().accept(decl.name(), key, generation)) {
                System.err.println("[persist] REJECTED a stale write to '" + decl.name()
                        + rowLabel(key) + "' (version " + generation + " < "
                        + runtime.versions().current(decl.name(), key) + ")");
                continue;
            }
            ConcurrentHashMap<String, Object> rows = cache.get(decl.name());
            Object value = rows != null ? rows.get(key) : null;
            if (value == null) {
                continue;
            }
            try {
                storage.writeBatch(decl.name(), Map.of(key, toJson(value)));
            } catch (Exception e) {
                // keep the marker so the crash checkpoint retries; the caller
                // holds the lease open until its TTL so nobody loads a stale copy
                markers.add(key);
                throw new ScriptError("flushing '" + decl.name() + rowLabel(key)
                        + "' failed: " + e.getMessage());
            }
        }
    }

    /**
     * §2.1.2: the EVICT half — "eviction is the half that prevents post-handoff
     * clobber". Once the rows are gone from memory nothing here can write them
     * again, whatever a stray task or the crash checkpoint does later.
     */
    public void evictSession(String key) {
        if (!mode.isNetwork()) {
            return;
        }
        NetworkRuntime runtime = network;
        for (PersistentDeclModel decl : declarations.values()) {
            if (!isSessionScoped(decl)) {
                continue;
            }
            ConcurrentHashMap<String, Object> rows = cache.get(decl.name());
            if (rows != null) {
                rows.remove(key);
            }
            Set<String> markers = dirty.get(decl.name());
            if (markers != null) {
                markers.remove(key);
            }
            if (runtime != null) {
                runtime.versions().clear(decl.name(), key);
            }
        }
    }

    /**
     * The write barrier for session rows: does the LEASE STORE still confirm we
     * own {@code key}?
     *
     * <p>{@code leases().holds()} answers from memory, and memory is exactly what
     * a partitioned or GC-paused server gets wrong — it goes on believing it owns
     * a session whose lease lapsed and which another server has since loaded.
     * Every path that can put a session row on the wire (the synchronous handoff
     * flush AND the crash checkpoint) asks this instead, so the §0 clobber has no
     * remaining window.
     *
     * <p>A proven loss is acted on immediately: the belief is dropped and the
     * rows are evicted, so this server stops being a writer for that subject
     * rather than re-discovering the same loss on every later cycle. An
     * unreachable lease store proves nothing, so the write is refused but nothing
     * is evicted (the data stays in memory and the TTL settles it).
     */
    private boolean stillOwnsSession(String key) {
        NetworkRuntime runtime = network;
        if (runtime == null) {
            return true;
        }
        LeaseManager.Ownership state = runtime.leases().check(key);
        if (state == LeaseManager.Ownership.LOST) {
            runtime.leases().forget(key);
            evictSession(key);
        }
        return state == LeaseManager.Ownership.HELD;
    }

    /**
     * The atomic write set of §3.2 — {@code add}, {@code subtract},
     * {@code append}, {@code set at}, and an unconditional {@code set}.
     *
     * <p>Standalone applies them in memory exactly like the read-modify-write
     * they replace. Network routes them by decl shape: a global goes through the
     * replica (applied at the backend, then broadcast); a session row this
     * server owns is applied in memory (single writer, no race); a session row
     * owned elsewhere is routed to its owner; and a session row nobody owns
     * (an offline subject) is applied straight at the backend.
     *
     * @param entryKey the map key for {@code set X at K to V}, else null
     * @return the value the row now holds
     */
    public Object atomic(String opName, String name, String key, Object operand,
            Object entryKey) {
        PersistentDeclModel decl = requireDeclared(name);
        AtomicOp op = AtomicOp.parse(opName);
        if (op == null) {
            throw new ScriptError("unknown atomic op '" + opName + "' on persistent '"
                    + name + "'");
        }
        NetworkRuntime runtime = network;
        if (mode.isNetwork() && runtime != null) {
            if (!isSessionScoped(decl)) {
                return runtime.replica().applyLocal(name, key, op, operand, entryKey);
            }
            if (!runtime.leases().holds(key)) {
                if (runtime.leases().heldElsewhere(key)) {
                    runtime.replica().routeOp(name, key, op, operand, entryKey);
                    return null;
                }
                return runtime.replica().applyOffline(name, key, op, operand, entryKey);
            }
        }
        Object next = op.apply(currentValue(decl, key), operand, entryKey);
        set(name, key, next);
        return next;
    }

    /**
     * Apply an atomic op another server routed here (§3.2). Only the server
     * that owns the subject's session acts on it — everyone else drops it, so
     * the op lands exactly once, on the live copy.
     */
    public void applyRoutedOp(NetMessage message) {
        PersistentDeclModel decl = declarations.get(message.var());
        NetworkRuntime runtime = network;
        if (decl == null || runtime == null || !isSessionScoped(decl)) {
            return;
        }
        if (!runtime.leases().holds(message.key())) {
            return;
        }
        AtomicOp op = message.atomicOp();
        if (op == null) {
            return;
        }
        Object operand = decodeRaw(message.value());
        Object entryKey = message.entry() == null || message.entry().isJsonNull()
                ? null : decodeRaw(message.entry());
        try {
            Object next = op.apply(currentValue(decl, message.key()), operand, entryKey);
            set(decl.name(), message.key(), next);
        } catch (Exception e) {
            System.err.println("[persist] a routed atomic op on '" + decl.name()
                    + rowLabel(message.key()) + "' failed: " + e.getMessage());
        }
    }

    /**
     * §3.1: is a read of {@code name} for {@code key} a REMOTE read — one this
     * server cannot answer out of its own cache?
     *
     * <p>True only for a session-owned row, under {@code mode: network}, whose
     * lease this server does not hold. That is the runtime half of the compiler
     * rule: the compiler demands an {@code await} whenever the subject's static
     * type is {@code OfflinePlayer} (it cannot know where the player is), and
     * this decides — per read, from the actual lease — whether that await gets a
     * real IO snapshot or a plain owned value. An owned subject stays a
     * synchronous cache read in both modes, which is what makes the same source
     * compile and behave the same way under either topology (§1).
     */
    public boolean isRemoteSession(String name, String key) {
        if (!mode.isNetwork()) {
            return false;
        }
        NetworkRuntime runtime = network;
        return runtime != null && isSessionScoped(declarations.get(name))
                && !runtime.leases().holds(key);
    }

    /**
     * §3.1: a read of a subject this server does not own is an IO snapshot, not
     * a cache read — the compiler turns it into a {@code Future<T>} the script
     * must {@code await}. Never touches (or poisons) the local cache.
     */
    public java.util.concurrent.CompletableFuture<Object> readRemote(String name, String key) {
        PersistentDeclModel decl = requireDeclared(name);
        return java.util.concurrent.CompletableFuture.supplyAsync(() -> {
            try {
                JsonElement stored = storage.load(decl.name(), key);
                Object value = stored == null ? null : coerceStoredValue(decl.type(), stored);
                return value != null ? value : defaultOf(decl.name());
            } catch (Exception e) {
                System.err.println("[persist] remote read of '" + decl.name()
                        + rowLabel(key) + "' failed: " + e.getMessage());
                return defaultOf(decl.name());
            }
        }, runnable -> Thread.ofVirtual().name("swoft-persist-remote-read").start(runnable));
    }

    /** The declared default of a persistent variable. */
    public Object defaultOf(String name) {
        return defaults.get(name);
    }

    /** Serialize a whole value of {@code name} for the backend / the bus. */
    public JsonElement encodeValue(String name, Object value) {
        PersistentDeclModel decl = requireDeclared(name);
        return toJson(coerceRuntime(decl, value));
    }

    /** Serialize an op operand or map key, with no declared type to coerce to. */
    public static JsonElement encodeRaw(Object value) {
        return value == null ? com.google.gson.JsonNull.INSTANCE : toJson(value);
    }

    /** Deserialize a stored/broadcast row of {@code name}; null when unusable. */
    public Object decodeValue(String name, JsonElement element) {
        PersistentDeclModel decl = declarations.get(name);
        if (decl == null || element == null) {
            return null;
        }
        return coerceStoredValue(decl.type(), element);
    }

    /**
     * Install a value into the local replica: cache only, no dirty marker. A
     * replicated global is already durable at the backend by the time it gets
     * here (the writer applied it there first), so re-flushing it would be a
     * write amplification at best and a clobber at worst.
     */
    public void putReplica(String name, String key, Object value) {
        if (!declarations.containsKey(name)) {
            return;
        }
        cache.computeIfAbsent(name, k -> new ConcurrentHashMap<>()).put(key, value);
        // §4.2, same reason set() does it: installing a replica row can add or
        // remove a reactive struct instance from the live set. This is the single
        // funnel for BOTH a local atomic op on a global and a change another
        // server broadcast, so covering it here covers every replica mutation.
        // A cheap flag check when no struct declares a reactive field.
        net.swofty.structs.InstanceReceiverRuntime.rebuild();
    }

    /** The live value of a row, falling back to the declared default. */
    private Object currentValue(PersistentDeclModel decl, String key) {
        ConcurrentHashMap<String, Object> rows = cache.get(decl.name());
        Object value = rows != null ? rows.get(key) : null;
        return value != null ? value : defaults.get(decl.name());
    }

    /**
     * A synchronous read of a session-owned row this server does not own would
     * silently answer with the declared default (§2.1: never serve defaults).
     * The compiler routes such reads through {@code await} instead, so reaching
     * here means something slipped past — say so, once per row.
     */
    private void warnUnownedRead(PersistentDeclModel decl, String key) {
        NetworkRuntime runtime = network;
        if (runtime == null || !isSessionScoped(decl) || runtime.leases().holds(key)) {
            return;
        }
        if (unownedWarned.add(decl.name() + ' ' + key)) {
            System.err.println("[persist] synchronous read of '" + decl.name()
                    + rowLabel(key) + "', a session this server does not own -"
                    + " the value is the declared default, not their data"
                    + " (await a remote read instead)");
        }
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
            boolean sessionVar = mode.isNetwork() && isSessionScoped(declarations.get(var));
            try {
                for (String key : taken) {
                    // Unmark before reading: a concurrent set() re-adds the
                    // marker, so its write can never be lost between cycles
                    keys.remove(key);
                    // §2.1.4: the timer is a CRASH CHECKPOINT, never the handoff
                    // path. A row whose lease we no longer hold belongs to
                    // another server now - writing it is exactly the post-handoff
                    // clobber, so drop it (the owner has the live copy).
                    //
                    // This asks the LEASE STORE, not the in-memory belief. The
                    // dangerous case is precisely the one where memory is wrong:
                    // this server paused (GC, partition), its lease lapsed, the
                    // player was picked up elsewhere, and it woke up still
                    // convinced it was the owner. One lease read per DIRTY session
                    // row per checkpoint interval is the price of closing that.
                    if (sessionVar && network != null && !stillOwnsSession(key)) {
                        continue;
                    }
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
            // after the final flush: hand every session over cleanly (release the
            // leases) and tear the replica subscription down. Doing this before
            // the flush would let another server load a session this one has not
            // written back yet.
            NetworkRuntime runtime = network;
            if (runtime != null) {
                network = null;
                try {
                    runtime.close();
                } catch (Exception e) {
                    System.err.println("Warning: closing the persistence network"
                            + " runtime failed: " + e.getMessage());
                }
            }
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
            // §2.3 lifecycle difference: globals load eagerly at boot and stay
            // live-synced; per-player values load lazily per join and are
            // evicted per leave. Eagerly loading every player's rows here would
            // both defeat ownership and pull the whole player table into memory.
            if (mode.isNetwork() && isSessionScoped(decl)) {
                cache.put(decl.name(), new ConcurrentHashMap<>());
                continue;
            }
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
            case OFFLINE_PLAYER:
                // an OfflinePlayer value persists by uuid (uuid-stable identity);
                // keep the live OfflinePlayerValue reference (uuid emitted at flush)
                if (value instanceof net.swofty.players.OfflinePlayerValue) {
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
        net.swofty.nativebridge.representation.DataType element = mapValueType(decl.type());
        for (Map.Entry<Object, Object> entry : map.entrySet()) {
            Object v = entry.getValue();
            if (NoneValue.isNone(v) || !matchesElement(element, v)) {
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
        for (Object v : list) {
            if (NoneValue.isNone(v) || !matchesElement(elemType, v)) {
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
            case OFFLINE_PLAYER:
                return value instanceof net.swofty.players.OfflinePlayerValue ? value : null;
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
            case OFFLINE_PLAYER: return v instanceof net.swofty.players.OfflinePlayerValue;
            default: return false;
        }
    }

    /**
     * Whether a live value matches a declared container-ELEMENT type — the
     * runtime twin of the checker's {@code serializable_ty} for a container
     * position. Beyond {@link #matchesLeaf} (scalars / Location / Vec / Item /
     * Player-uuid) this admits a {@link StructValue} of the declared struct type
     * and recurses through nested list/map/optional elements, so a
     * {@code persistent duels: Map<String, Duel>} accepts a Duel value (its
     * fields are serialized/rehydrated by {@code structToJson}/{@code
     * structFromJson}). Without this a persistence-rooted reactive struct could
     * never be stored, and §4.2 liveness would have no surviving root.
     */
    private static boolean matchesElement(
            net.swofty.nativebridge.representation.DataType type, Object v) {
        if (type == null) {
            return false;
        }
        BaseType base = type.getBaseType();
        switch (base) {
            case STRUCT:
                return v instanceof StructValue struct
                        && (type.getTypeName() == null
                                || struct.typeName().equals(type.getTypeName()));
            case LIST: {
                if (!(v instanceof List<?> list)) {
                    return false;
                }
                net.swofty.nativebridge.representation.DataType el = listElementType(type);
                for (Object e : list) {
                    if (NoneValue.isNone(e) || !matchesElement(el, e)) {
                        return false;
                    }
                }
                return true;
            }
            case MAP: {
                if (!(v instanceof net.swofty.runtime.MapValue map)) {
                    return false;
                }
                net.swofty.nativebridge.representation.DataType val = mapValueType(type);
                for (Object e : map.values()) {
                    if (NoneValue.isNone(e) || !matchesElement(val, e)) {
                        return false;
                    }
                }
                return true;
            }
            case OPTIONAL:
                return NoneValue.isNone(v) || matchesElement(listElementType(type), v);
            default:
                return matchesLeaf(base, v);
        }
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
            case OFFLINE_PLAYER:
                return offlinePlayerFromJson(element);
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
     * Resolve a stored OfflinePlayer (a uuid string) back to an
     * {@link net.swofty.players.OfflinePlayerValue}. Unlike a live Player this
     * never culls: an offline identity is always resolvable — the name is
     * re-hydrated from the seen-players store (or "unknown" when unseen). A
     * non-string / unparseable blob is a bad row (null).
     */
    private static Object offlinePlayerFromJson(JsonElement blob) {
        if (blob == null || !blob.isJsonPrimitive()) {
            return null;
        }
        try {
            java.util.UUID uuid = java.util.UUID.fromString(blob.getAsString());
            return net.swofty.players.SeenPlayersStore.byUuid(uuid.toString());
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
        return healStruct(def, blob.getAsJsonObject());
    }

    /**
     * Load a stored struct blob into a live instance, tolerating schema drift —
     * this NEVER returns null and NEVER throws on a shape mismatch (worst case a
     * default-filled instance + a warning). Two tiers:
     *
     * <p>Tier 2 (versioned migration): read the stored {@code __schema} version
     * (absent =&gt; 1); if it is below the struct's current schema, run the
     * {@code migrate to k} blocks in ascending order with the raw prior fields
     * bound, collecting the field values they assign.
     *
     * <p>Tier 1 (auto-heal, always): for every field of the CURRENT struct, use
     * the migrate-produced value if any, else the stored value when present and
     * type-compatible, else the field default (silent when the field has one; a
     * once-only warning + the type zero/none when it does not). A type-
     * incompatible kept value falls back to the field default + a warning. Any
     * stored field not in the current struct is dropped silently.
     */
    private static StructValue healStruct(StructDefModel def, com.google.gson.JsonObject object) {
        int storedVersion = readStoredSchema(object);
        int current = def.schemaVersion();
        if (storedVersion > current) {
            // downgrade: the blob was written by a newer schema than this build
            // knows. There are no migrate blocks running backwards, so just load
            // best-effort through Tier-1 (kept fields used, unknown newer fields
            // dropped) and warn once — never crash or corrupt.
            warnDowngrade(def, storedVersion, current);
        }
        Map<String, Object> produced =
                (current > 1 && storedVersion < current && !def.migrationsInOrder().isEmpty())
                        ? runMigrations(def, object, storedVersion, current)
                        : Map.of();

        LinkedHashMap<String, Object> values = new LinkedHashMap<>();
        for (StructFieldModel field : def.fields()) {
            String name = field.name();
            Object value;
            if (produced.containsKey(name)) {
                // a migrate block assigned this field; validate it against the
                // field type by round-tripping through the typed decoder
                Object coerced = coerceProduced(field.type(), produced.get(name));
                if (coerced != null || field.type().getBaseType() == BaseType.OPTIONAL) {
                    value = coerced;
                } else {
                    warnDrift(def, field, "migration produced an incompatible value for");
                    value = fieldDefaultOrZero(def, field, false);
                }
            } else {
                JsonElement element = object.get(name);
                if (element != null && !element.isJsonNull()) {
                    Object stored = coerceStoredValue(field.type(), element);
                    if (stored != null) {
                        value = stored;
                    } else {
                        warnDrift(def, field, "incompatible stored value for");
                        value = fieldDefaultOrZero(def, field, false);
                    }
                } else if (field.type().getBaseType() == BaseType.OPTIONAL) {
                    // an absent optional field is legitimately none (silent)
                    value = NoneValue.INSTANCE;
                } else {
                    // absent required field: silent when it has a default,
                    // otherwise warn once and use the type zero/none
                    value = fieldDefaultOrZero(def, field, true);
                }
            }
            values.put(name, value == null ? NoneValue.INSTANCE : value);
        }
        return new StructValue(def.name(), values);
    }

    /** The stored schema version of a struct blob; absent/garbage =&gt; 1. */
    private static int readStoredSchema(com.google.gson.JsonObject object) {
        JsonElement element = object.get(SCHEMA_FIELD);
        if (element != null && element.isJsonPrimitive()) {
            try {
                return Math.max(1, element.getAsInt());
            } catch (Exception ignored) {
                // fall through to the default
            }
        }
        return 1;
    }

    /**
     * Run the {@code migrate to k} blocks that upgrade a stored row from
     * {@code storedVersion} up to {@code current}, in ascending order, through
     * the normal statement runtime. The raw prior fields are bound both as bare
     * variables and under a {@code raw} map so a block can read {@code title} or
     * {@code raw["title"]}. A block assigns the new-shape fields with plain
     * {@code set <field> to ...} statements. Returns the field values the blocks
     * actually produced — a variable that a block newly bound or changed from
     * its bound old value. A failing block is warned and skipped (never crashes
     * the load); Tier-1 auto-heal then fills anything left untouched.
     */
    private static Map<String, Object> runMigrations(StructDefModel def,
            com.google.gson.JsonObject object, int storedVersion, int current) {
        Map<String, Object> vars = new HashMap<>();
        net.swofty.runtime.MapValue raw = new net.swofty.runtime.MapValue();
        for (Map.Entry<String, JsonElement> entry : object.entrySet()) {
            if (SCHEMA_FIELD.equals(entry.getKey())) {
                continue;
            }
            Object decoded = decodeRaw(entry.getValue());
            raw.put(entry.getKey(), decoded);
            vars.put(entry.getKey(), decoded);
        }
        vars.put("raw", raw);
        Map<String, Object> before = new HashMap<>(vars);

        ASTExecutor executor = new ASTExecutor(null, vars);
        for (net.swofty.model.MigrateBlockModel migrate : def.migrationsInOrder()) {
            if (migrate.toVersion() <= storedVersion || migrate.toVersion() > current) {
                continue;
            }
            try {
                executor.context().runBlock(migrate.body());
            } catch (Exception e) {
                System.err.println("Warning: migrate to " + migrate.toVersion() + " for struct '"
                        + def.name() + "' failed: " + e.getMessage()
                        + " - auto-heal will fill the rest from defaults");
            }
        }

        // a field the migration touched: a bare var it newly bound, or whose
        // value it changed from the bound old value. Untouched old fields carry
        // through Tier-1's typed stored-value path instead (so a richly-typed
        // unchanged field is not corrupted by the generic raw decode).
        Map<String, Object> produced = new HashMap<>();
        for (StructFieldModel field : def.fields()) {
            String name = field.name();
            if (!vars.containsKey(name)) {
                continue;
            }
            Object now = vars.get(name);
            if (!before.containsKey(name) || !java.util.Objects.equals(now, before.get(name))) {
                produced.put(name, now);
            }
        }
        return produced;
    }

    /**
     * Decode a stored JSON element into a generic runtime value for a migrate
     * block to read (no declared old-field types are available at load): objects
     * become MapValues, arrays ArrayLists, integral numbers Integers, and other
     * numbers Doubles. Symmetric enough with the script value model that a
     * migrate expression sees the old fields as ordinary maps/lists/scalars.
     */
    private static Object decodeRaw(JsonElement element) {
        if (element == null || element.isJsonNull()) {
            return NoneValue.INSTANCE;
        }
        if (element.isJsonPrimitive()) {
            JsonPrimitive primitive = element.getAsJsonPrimitive();
            if (primitive.isBoolean()) {
                return primitive.getAsBoolean();
            }
            if (primitive.isNumber()) {
                double d = primitive.getAsDouble();
                if (d == Math.rint(d) && !Double.isInfinite(d)
                        && Math.abs(d) <= Integer.MAX_VALUE) {
                    return (int) d;
                }
                return d;
            }
            return primitive.getAsString();
        }
        if (element.isJsonArray()) {
            List<Object> out = new java.util.ArrayList<>();
            for (JsonElement child : element.getAsJsonArray()) {
                out.add(decodeRaw(child));
            }
            return out;
        }
        net.swofty.runtime.MapValue map = new net.swofty.runtime.MapValue();
        for (Map.Entry<String, JsonElement> entry : element.getAsJsonObject().entrySet()) {
            map.put(entry.getKey(), decodeRaw(entry.getValue()));
        }
        return map;
    }

    /**
     * Validate a migrate-produced runtime value against a field's declared type
     * by round-tripping it through the typed serializer + decoder (so a produced
     * struct/list/map/scalar reloads exactly as a stored one would). Returns the
     * coerced value, or null when the value cannot satisfy the field type (the
     * caller then falls back to the field default + warn). none for an optional
     * field decodes back to none.
     */
    private static Object coerceProduced(DataType type, Object value) {
        try {
            return coerceStoredValue(type, toJson(value));
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * The value to use for a field the stored row could not supply: the field's
     * evaluated default when it has one (silent), otherwise the type zero/none.
     * When {@code silentWithoutDefault} is false the no-default case still warns
     * once (a type-incompatible or migration-failed field always deserves a
     * warning); when true it warns once only if the field also has no default
     * (a plainly-missing required field).
     */
    private static Object fieldDefaultOrZero(StructDefModel def, StructFieldModel field,
            boolean silentWithoutDefault) {
        if (field.hasDefault()) {
            try {
                return sharedExecutor().evaluateExpression(field.defaultValue());
            } catch (Exception e) {
                // fall through to the type zero/none
            }
        } else if (silentWithoutDefault) {
            warnDrift(def, field, "missing stored value (no default) for");
        }
        return zeroFieldValue(field.type());
    }

    /** The type zero/none for a struct field: nested structs default-fill. */
    private static Object zeroFieldValue(DataType type) {
        if (type.getBaseType() == BaseType.STRUCT) {
            StructDefModel nested = StructRegistry.get(type.getTypeName());
            return nested != null
                    ? healStruct(nested, new com.google.gson.JsonObject())
                    : NoneValue.INSTANCE;
        }
        return zeroValue(type.getBaseType());
    }

    /** A bare executor for evaluating struct-field default expressions on load. */
    private static ASTExecutor sharedExecutor() {
        ASTExecutor executor = healExecutor;
        if (executor == null) {
            executor = new ASTExecutor(null, new HashMap<>());
            healExecutor = executor;
        }
        return executor;
    }

    /** Warn at most once per struct that a stored blob is from a newer schema. */
    private static void warnDowngrade(StructDefModel def, int storedVersion, int current) {
        String key = def.name() + "#__downgrade#" + storedVersion + ">" + current;
        if (driftWarned.add(key)) {
            System.err.println("Warning: struct '" + def.name() + "' stored schema version "
                    + storedVersion + " is newer than this build's schema " + current
                    + " - loading best-effort (fields unknown to this version are dropped)");
        }
    }

    /** Warn at most once per (struct, field, reason) so a bad column never spams. */
    private static void warnDrift(StructDefModel def, StructFieldModel field, String reason) {
        String key = def.name() + "#" + field.name() + "#" + reason;
        if (driftWarned.add(key)) {
            System.err.println("Warning: struct '" + def.name() + "' field '" + field.name()
                    + "': " + reason + " it - using the field default");
        }
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
        // stamp the current schema version so a later load can detect drift and
        // run the versioned migrate-to-k blocks (Tier-2). Written for every
        // known struct blob (top-level and nested); an absent __schema on load
        // means version 1 (rows written before schema versioning existed).
        object.addProperty(SCHEMA_FIELD, def.schemaVersion());
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
        // OfflinePlayer -> uuid string (uuid-stable; name re-resolved on load).
        // Symmetric with a Player value and with mapKeyToJsonKey, so an
        // OfflinePlayer value and an OfflinePlayer map key store the same form.
        if (value instanceof net.swofty.players.OfflinePlayerValue offline) {
            return new JsonPrimitive(offline.uuid());
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
                || base == BaseType.PLAYER || base == BaseType.OFFLINE_PLAYER;
    }

    /**
     * A persistent may hold a leaf value (scalar / Location / Vec / Item /
     * Player-uuid), a persistable struct, or a list/map/optional whose element is
     * itself container-persistable. list&lt;T&gt; serializes as a JSON array and
     * map&lt;K, T&gt; as a whole-map JSON object per row; both encode/decode
     * recurse into struct elements ({@code structToJson} / {@code structFromJson}),
     * so a {@code Map<String, Duel>} or {@code List<Guild>} of a serializable
     * struct persists exactly like the compiler's checker (tc_decl serializable_ty)
     * accepts it. This mirrors {@link #isFieldPersistable} for the container
     * element rather than {@link #isLeafPersistable}: the old leaf-only gate
     * wrongly rejected the canonical persistence-rooted reactive struct
     * ({@code persistent duels: Map<String, Duel>}) even though the checker
     * approved it and both serialization paths handle it — leaving the reactive
     * instance's liveness with no surviving persistent root to re-derive from.
     */
    private static boolean isPersistable(
            net.swofty.nativebridge.representation.DataType type) {
        BaseType base = type.getBaseType();
        if (isLeafPersistable(type)) {
            return true;
        }
        if (base == BaseType.LIST) {
            net.swofty.nativebridge.representation.DataType element = listElementType(type);
            return element != null && isFieldPersistable(element, new java.util.HashSet<>());
        }
        if (base == BaseType.MAP) {
            net.swofty.nativebridge.representation.DataType value = mapValueType(type);
            return value != null && isFieldPersistable(value, new java.util.HashSet<>());
        }
        // optional<T> persists exactly like T (present) or JSON null (none)
        if (base == BaseType.OPTIONAL) {
            net.swofty.nativebridge.representation.DataType inner = listElementType(type);
            return inner != null && isFieldPersistable(inner, new java.util.HashSet<>());
        }
        // a struct persists (§3.2) iff every one of its fields is persistable;
        // struct fields may themselves be leaves, nested structs, or
        // list/map/optional of those
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
