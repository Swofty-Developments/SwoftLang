package net.swofty.persist.network;

/**
 * The ownership record store behind {@link LeaseManager} (design 1.10.0 §2.1):
 * exactly one server may hold the lease on a subject key at a time, and a
 * crashed holder's lease expires by TTL so the subject is never stranded.
 *
 * <p>Two implementations: {@link RedisLeaseStore} (a real compare-and-set via
 * {@code SET NX PX}, used when a {@code coordinator:} is configured) and
 * {@link BackendLeaseStore} (a lease table inside the shared backend, the
 * default). Both are safe to call from any thread.
 */
public interface LeaseStore {

    /**
     * One ownership record. {@code generation} is the monotonic version stamp of
     * design §2.1.3: it increases on every successful acquisition, so a write
     * carrying an older generation is a late writer that lost the handoff and
     * MUST be rejected.
     */
    record Lease(String key, String owner, long generation, long expiresAtMillis) {

        public boolean isHeldBy(String candidate) {
            return owner != null && owner.equals(candidate);
        }

        public boolean isExpired(long nowMillis) {
            return expiresAtMillis <= nowMillis;
        }
    }

    /**
     * A lease record could not be READ. Distinct from "the lease is unheld",
     * which {@link #peek} reports as null: an unreachable coordinator must never
     * be mistaken for a free subject (that would let a second server in) nor for
     * a lost one (that would evict a live player's data mid-session).
     */
    final class LeaseStoreException extends RuntimeException {
        public LeaseStoreException(String message, Throwable cause) {
            super(message, cause);
        }
    }

    /**
     * Try to take the lease on {@code key} for {@code owner}.
     * @return the granted lease, or null when another live server still holds it
     *         (the handoff barrier: B cannot acquire until A released or A's TTL
     *         lapsed) — and also null when the store could not be reached, since
     *         an unprovable handoff must fail closed
     */
    Lease acquire(String key, String owner, long ttlMillis);

    /**
     * The current record for {@code key}, or null when unheld.
     * @throws LeaseStoreException when the record could not be read at all
     */
    Lease peek(String key);

    /**
     * Push the expiry of a lease this server holds further out.
     * @return false only when this server is OBSERVED not to hold the lease any
     *         more (it lapsed and someone else took the subject) — the caller
     *         treats that as a lost session. A store that cannot be reached
     *         returns true: nothing was observed, so nothing is concluded, and
     *         the lease lapses by TTL if the outage persists.
     */
    boolean renew(String key, String owner, long ttlMillis);

    /** Give up a lease this server holds. A lease held by anyone else is untouched. */
    void release(String key, String owner);

    /** Release any client/connection resources. */
    void close();
}
