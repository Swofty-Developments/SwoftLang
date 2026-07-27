package net.swofty.persist.network;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Session ownership (design 1.10.0 §2.1): acquire a subject's lease before its
 * data is loaded, renew it while the player is here, release it after the
 * save-and-evict on quit.
 *
 * <p>Three properties this class exists to guarantee:
 * <ol>
 *   <li><b>Handoff barrier</b> — {@link #acquire} retries against the lease
 *       store until the previous holder releases or its TTL lapses, and gives up
 *       at {@code acquireTimeoutMillis}. It NEVER "wins" by ignoring a live
 *       lease, so two servers can never own one player at once.</li>
 *   <li><b>TTL</b> — a crashed server stops renewing, so its leases expire and
 *       the player can be picked up elsewhere. A renewal loop keeps the leases
 *       of live sessions from lapsing under a long GC pause or a hot reload.</li>
 *   <li><b>Monotonic generation</b> — every successful acquire returns a strictly
 *       higher stamp than the previous holder's, which {@link VersionStamps}
 *       uses to reject a late writer's flush.</li>
 * </ol>
 */
public final class LeaseManager {

    /** Default lease lifetime; a crashed server's sessions free up after this. */
    public static final long DEFAULT_TTL_MILLIS = 30_000L;

    /** How long a join waits at the handoff barrier before giving up. */
    public static final long DEFAULT_ACQUIRE_TIMEOUT_MILLIS = 5_000L;

    private static final long RETRY_SLEEP_MILLIS = 100L;

    /** Sentinel returned by {@link #acquire} when the handoff failed. */
    public static final long NO_LEASE = -1L;

    private final LeaseStore store;
    private final String owner;
    private final long ttlMillis;
    private final long acquireTimeoutMillis;

    /** subject key to the generation we hold it at. */
    private final Map<String, Long> held = new ConcurrentHashMap<>();

    private volatile boolean running = true;
    private Thread renewer;

    /** Invoked when a lease is discovered to be lost; see {@link #onLeaseLost}. */
    private volatile java.util.function.Consumer<String> leaseLost;

    /**
     * What the LEASE STORE says about a subject we believe we own.
     *
     * <p>The three-way answer is the point. Collapsing {@link #UNKNOWN} into
     * {@link #LOST} would evict a live player's data every time the coordinator
     * blinked; collapsing it into {@link #HELD} would let a partitioned server
     * keep writing over the new owner. So an unreadable store means "refuse the
     * write, conclude nothing" — and the TTL settles it if the outage lasts.
     */
    public enum Ownership {
        /** The store confirms this server holds it, at the generation we took. */
        HELD,
        /** The store proves we do NOT hold it any more (lapsed, or taken over). */
        LOST,
        /** The store could not be read; ownership is unproven either way. */
        UNKNOWN
    }

    public LeaseManager(LeaseStore store, String owner) {
        this(store, owner, DEFAULT_TTL_MILLIS, DEFAULT_ACQUIRE_TIMEOUT_MILLIS);
    }

    public LeaseManager(LeaseStore store, String owner, long ttlMillis,
            long acquireTimeoutMillis) {
        this.store = store;
        this.owner = owner;
        this.ttlMillis = ttlMillis;
        this.acquireTimeoutMillis = acquireTimeoutMillis;
        startRenewLoop();
    }

    /**
     * Take ownership of {@code key}, waiting out a previous holder up to the
     * acquire timeout.
     * @return the monotonic generation of the granted lease, or {@link #NO_LEASE}
     *         when the handoff failed (caller applies {@code on_handoff_failure};
     *         it must NEVER fall back to defaults)
     */
    public long acquire(String key) {
        long deadline = System.currentTimeMillis() + acquireTimeoutMillis;
        while (true) {
            LeaseStore.Lease lease = store.acquire(key, owner, ttlMillis);
            if (lease != null) {
                held.put(key, lease.generation());
                return lease.generation();
            }
            if (System.currentTimeMillis() >= deadline) {
                LeaseStore.Lease blocking = store.peek(key);
                System.err.println("[persist] handoff barrier: could not acquire the session"
                        + " lease for " + key + " within " + acquireTimeoutMillis + "ms"
                        + (blocking != null && blocking.owner() != null
                                ? " (still held by '" + blocking.owner() + "')" : ""));
                return NO_LEASE;
            }
            try {
                Thread.sleep(RETRY_SLEEP_MILLIS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return NO_LEASE;
            }
        }
    }

    /** Whether this server currently holds {@code key} at {@code generation}. */
    public boolean holds(String key, long generation) {
        Long current = held.get(key);
        return current != null && current == generation;
    }

    /** Whether this server currently holds {@code key} at any generation. */
    public boolean holds(String key) {
        return held.containsKey(key);
    }

    /**
     * Ask the lease store — not our own memory — whether we still own
     * {@code key}, at the generation we took it at.
     *
     * <p>The in-memory {@code held} map only records what we BELIEVE. A long GC
     * pause, a partition, or a lost connection can lapse our lease while we go on
     * believing; another server then legitimately picks the subject up at a
     * higher generation. Everything that is about to WRITE a session row has to
     * ask this first, because {@link #holds} would happily say yes and produce
     * exactly the §0 clobber.
     */
    public Ownership check(String key) {
        Long generation = held.get(key);
        if (generation == null) {
            return Ownership.LOST;
        }
        LeaseStore.Lease lease;
        try {
            lease = store.peek(key);
        } catch (Exception e) {
            System.err.println("[persist] cannot verify the lease for " + key
                    + ": " + e.getMessage() + " - treating ownership as unproven");
            return Ownership.UNKNOWN;
        }
        boolean ours = lease != null && lease.isHeldBy(owner)
                && lease.generation() == generation
                && !lease.isExpired(System.currentTimeMillis());
        return ours ? Ownership.HELD : Ownership.LOST;
    }

    /**
     * Whether the store CONFIRMS we hold {@code key}. Anything short of a
     * confirmation is false, so a write gated on this fails closed.
     */
    public boolean verifyHeld(String key) {
        return check(key) == Ownership.HELD;
    }

    /**
     * Drop the belief that we own {@code key} without touching the store — used
     * when {@link #check} proved the lease is gone. The lease already belongs to
     * someone else (or to nobody), so releasing it would be wrong; what has to
     * happen is that this server stops acting like the owner, which the
     * {@link #onLeaseLost} listener completes by evicting the rows.
     */
    public void forget(String key) {
        if (held.remove(key) == null) {
            return;
        }
        java.util.function.Consumer<String> listener = leaseLost;
        if (listener != null) {
            listener.accept(key);
        }
    }

    /**
     * Install the "we lost this session" listener — the store's evictor. Set once
     * at startup by {@link NetworkRuntime}.
     */
    public void onLeaseLost(java.util.function.Consumer<String> listener) {
        this.leaseLost = listener;
    }

    /**
     * Whether some OTHER live server currently owns {@code key}. An unreadable
     * lease store answers true: routing an op to a possibly-live owner loses the
     * op at worst, whereas answering false would apply it at the backend behind
     * that owner's back and be overwritten by their session flush.
     */
    public boolean heldElsewhere(String key) {
        if (held.containsKey(key)) {
            return false;
        }
        LeaseStore.Lease lease;
        try {
            lease = store.peek(key);
        } catch (Exception e) {
            System.err.println("[persist] cannot read the lease for " + key
                    + ": " + e.getMessage() + " - assuming another server owns it");
            return true;
        }
        return lease != null && lease.owner() != null && !lease.isHeldBy(owner)
                && !lease.isExpired(System.currentTimeMillis());
    }

    /** The generation we hold {@code key} at, or {@link #NO_LEASE}. */
    public long generation(String key) {
        Long current = held.get(key);
        return current == null ? NO_LEASE : current;
    }

    /** Every subject key this server currently owns. */
    public List<String> heldKeys() {
        return new ArrayList<>(held.keySet());
    }

    /**
     * Give up a lease. Called only AFTER the synchronous save + evict.
     *
     * <p>It evicts again on the way out, via the {@link #onLeaseLost} listener.
     * Between the caller's evict and this release the lease is still ours, so a
     * stray task's write is still accepted and quietly re-populates the row that
     * was just dropped — a value nothing will ever flush, that a synchronous read
     * would answer with, and that would outlive the session in memory. After the
     * release no write can get back in, so this is the last word.
     */
    public void release(String key) {
        if (held.remove(key) == null) {
            return;
        }
        store.release(key, owner);
        java.util.function.Consumer<String> listener = leaseLost;
        if (listener != null) {
            listener.accept(key);
        }
    }

    /**
     * Push every held lease's expiry out. Called by the renewal loop and,
     * critically, by the hot-reload hook (§6): a reload must not let a still
     * connected player's lease lapse while the program is being rebuilt.
     *
     * <p>It is also the SELF-HEALING path. A renewal that comes back "you do not
     * hold this any more" is proof that the lease lapsed and another server took
     * the subject — so the belief and the cached rows are dropped here, within a
     * renewal period, rather than surviving until something tries to write them.
     */
    public void renewAll() {
        for (String key : held.keySet()) {
            try {
                if (!store.renew(key, owner, ttlMillis)) {
                    System.err.println("[persist] LOST the session lease for " + key
                            + " (it lapsed and another server took it) - dropping"
                            + " this server's copy so nothing can write it back");
                    forget(key);
                }
            } catch (Exception e) {
                System.err.println("[persist] lease renew failed for " + key
                        + ": " + e.getMessage());
            }
        }
    }

    private void startRenewLoop() {
        long period = Math.max(1_000L, ttlMillis / 3);
        renewer = Thread.ofVirtual().name("swoft-persist-lease-renew").start(() -> {
            while (running) {
                try {
                    Thread.sleep(period);
                } catch (InterruptedException e) {
                    return;
                }
                if (running) {
                    renewAll();
                }
            }
        });
    }

    /**
     * Stop renewing and release every held lease — the clean-shutdown path, so
     * a restart hands its players over immediately instead of making the next
     * server wait out the TTL. The caller must have flushed + evicted first.
     */
    public void close() {
        running = false;
        if (renewer != null) {
            renewer.interrupt();
        }
        for (String key : heldKeys()) {
            release(key);
        }
        store.close();
    }
}
