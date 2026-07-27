package net.swofty.persist.network;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.google.gson.JsonElement;
import com.google.gson.JsonParser;

import net.swofty.ScriptError;
import net.swofty.persist.change.CausalityToken;
import net.swofty.persist.PersistStore;
import net.swofty.persist.SwoftStorage;

/**
 * Replicated globals (design 1.10.0 §2.2): every server holds a local replica of
 * every global persistent value, loaded eagerly at boot (§2.3) and kept fresh by
 * broadcast. Reads stay synchronous and fast off that replica; writes are atomic
 * ops applied AT THE BACKEND and then published to the other servers.
 *
 * <p><b>The write is a compare-and-set retry loop, not a lock.</b> §3.2 makes
 * {@code set pot to pot + 50} a compile error precisely because a read-modify-
 * write racing in two JVMs loses updates — so the runtime must not do one either.
 * Each atomic op:
 * <ol>
 *   <li>re-reads the row from the backend (the replica may be a broadcast hop
 *       stale, and an op has to compose with whatever other servers did);</li>
 *   <li>applies the op and writes the result back CONDITIONALLY on the row still
 *       reading exactly what was read — see
 *       {@link SwoftStorage#compareAndSet};</li>
 *   <li>on a losing swap, re-composes against what is actually stored and tries
 *       again, so two servers' concurrent {@code add 50 to pot} always total
 *       100;</li>
 *   <li>updates the local replica and publishes the new row stamped with
 *       {@code origin_server} and a monotonic version.</li>
 * </ol>
 * This costs two round-trips uncontended — cheaper than any distributed lock —
 * and it needs no coordinator, so a mysql-only deployment is just as correct as a
 * redis-coordinated one.
 *
 * <p>The originating server applies the change to its own replica directly and
 * ignores the echo of its own broadcast (§5.4).
 */
public final class GlobalReplica {

    /** Bound on the CAS retry loop; exceeding it is reported, never swallowed. */
    private static final int CAS_ATTEMPTS = 64;

    private final PersistStore store;
    private final SwoftStorage storage;
    private final BroadcastChannel channel;
    private final VersionStamps versions;
    private final String origin;

    /**
     * Per-row monitors, so two script threads on THIS server never burn CAS
     * attempts against each other. Purely an optimisation — correctness comes
     * from the conditional write, which does not care who the contender is.
     */
    private final Map<String, Object> monitors = new ConcurrentHashMap<>();

    public GlobalReplica(PersistStore store, SwoftStorage storage, BroadcastChannel channel,
            VersionStamps versions, String origin) {
        this.store = store;
        this.storage = storage;
        this.channel = channel;
        this.versions = versions;
        this.origin = origin;
    }

    /** Begin receiving other servers' changes. */
    public void start() {
        channel.subscribe(this::applyRemote);
    }

    /**
     * Route an atomic op to whichever server owns a session-owned row (§3.2
     * "routed to owner"). The owner applies it to its live copy; this server
     * only publishes it.
     */
    public void routeOp(String var, String key, AtomicOp op, Object operand, Object entryKey,
            CausalityToken cause) {
        // the operand of an op is not a whole value (the element of a list, the
        // amount of an add), so it is encoded raw rather than coerced to the
        // declared type. The causality token rides along so the owner's change
        // handlers continue this chain rather than starting a fresh one (§5.3).
        channel.publish(NetMessage.op(var, key, op, PersistStore.encodeRaw(operand),
                PersistStore.encodeRaw(entryKey), origin, cause));
    }

    /**
     * Apply an atomic op straight at the backend — the offline-subject path,
     * where no server holds the session and the stored row IS the value.
     */
    public Object applyOffline(String var, String key, AtomicOp op, Object operand,
            Object entryKey, CausalityToken cause) {
        synchronized (monitor("session:" + var + ':' + key)) {
            // no server holds this session, so the row is not in anyone's memory
            // and there is nothing to fire a change event against here (§2.1:
            // session rows live on their owner). The backend value still moves.
            return compose(var, key, op, operand, entryKey, false, cause);
        }
    }

    /**
     * Apply an atomic op to a global row here and everywhere.
     *
     * @param entryKey the map key for {@link AtomicOp#MAP_SET}, else null
     * @return the value the row now holds
     */
    public Object applyLocal(String var, String key, AtomicOp op, Object operand,
            Object entryKey, CausalityToken cause) {
        synchronized (monitor("global:" + var + ':' + key)) {
            return compose(var, key, op, operand, entryKey, true, cause);
        }
    }

    /**
     * The compare-and-set retry loop both write paths share: read the row, apply
     * the op, and write it back only if nothing moved underneath. A losing swap
     * hands back what IS stored, so the next attempt composes against the other
     * server's result instead of overwriting it — which is exactly what makes two
     * concurrent {@code add 50 to pot} total 100 rather than 50.
     */
    private Object compose(String var, String key, AtomicOp op, Object operand,
            Object entryKey, boolean publish, CausalityToken cause) {
        String expected = readRaw(var, key);
        for (int attempt = 0; attempt < CAS_ATTEMPTS; attempt++) {
            Object current = decode(var, expected);
            Object next = op.apply(current, operand, entryKey);
            JsonElement encoded = store.encodeValue(var, next);
            SwoftStorage.CasOutcome outcome =
                    storage.compareAndSet(var, key, expected, encoded.toString());
            if (outcome.swapped()) {
                if (publish) {
                    // §4.1: the writer fires its own handlers here (caused_here
                    // = true) and then publishes; every other server fires from
                    // applyRemote with caused_here = false.
                    store.putReplica(var, key, next, true, cause);
                    long version = versions.nextGlobal(var, key);
                    channel.publish(NetMessage.value(var, key, encoded, origin, version, cause));
                }
                return next;
            }
            expected = outcome.observed();
        }
        // Never silently drop a write: an op that cannot be applied atomically is
        // an error the script author has to see, not a number that quietly drifts.
        throw new ScriptError("an atomic op on persistent '" + var + "' lost "
                + CAS_ATTEMPTS + " compare-and-set races in a row - the backend row"
                + " is being rewritten faster than it can be composed with");
    }

    private Object monitor(String lock) {
        return monitors.computeIfAbsent(lock, k -> new Object());
    }

    /** The row exactly as the backend stores it, or null when absent. */
    private String readRaw(String var, String key) {
        JsonElement stored;
        try {
            stored = storage.load(var, key);
        } catch (Exception e) {
            // Applying to the local replica instead would diverge this server from
            // every other one and then broadcast the divergence. Fail loudly.
            throw new ScriptError("an atomic op on persistent '" + var
                    + "' could not read the backend: " + e.getMessage());
        }
        return stored == null || stored.isJsonNull() ? null : stored.toString();
    }

    /** The stored text as a value of {@code var}, falling back to its default. */
    private Object decode(String var, String raw) {
        if (raw != null) {
            try {
                Object decoded = store.decodeValue(var, JsonParser.parseString(raw));
                if (decoded != null) {
                    return decoded;
                }
            } catch (Exception e) {
                System.err.println("[persist] stored value of '" + var
                        + "' is unreadable (" + raw + ") - composing from the default");
            }
        }
        return store.defaultOf(var);
    }

    /**
     * Apply a change another server published. Stale/duplicate deliveries are
     * dropped by the version stamp, so a replica can never roll backwards.
     */
    public void applyRemote(NetMessage message) {
        // §5.4 self-echo suppression: this server already applied the change and
        // already fired its handlers (caused_here = true) before publishing, so
        // its own echo must not be applied - or fired - a second time.
        if (origin.equals(message.origin())) {
            return;
        }
        if (!store.isDeclared(message.var())) {
            // another program on the same backend - not ours to apply
            return;
        }
        if (NetMessage.KIND_OP.equals(message.kind())) {
            // an atomic op aimed at a session-owned row: only its owner acts
            store.applyRoutedOp(message);
            return;
        }
        if (!NetMessage.KIND_VALUE.equals(message.kind())) {
            return;
        }
        if (!versions.accept(message.var(), message.key(), message.version())) {
            return;
        }
        Object value = store.decodeValue(message.var(), message.value());
        if (value == null) {
            System.err.println("[persist] broadcast for '" + message.var()
                    + "' carried a value this program cannot hold - ignored");
            return;
        }
        // §4.1: fires here too, with caused_here = false, and §5.3: the change
        // continues the chain the message carries, so a cascade that bounces
        // between servers accumulates depth instead of resetting on every hop.
        store.putReplica(message.var(), message.key(), value, false, message.cause());
    }

}
