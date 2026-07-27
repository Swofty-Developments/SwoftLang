package net.swofty.persist.network;

import java.io.IOException;

/**
 * Lease store on a redis coordinator (design 1.10.0 §1 {@code coordinator:}).
 *
 * <p>Acquisition is a genuine atomic compare-and-set: {@code SET key owner NX PX
 * ttl} succeeds for exactly one server, and redis expires the key on its own if
 * the holder crashes — the TTL of §2.1.5 with no sweeper to write. The monotonic
 * generation is a separate {@code INCR} counter bumped only by the winner, so a
 * stale write from the previous holder always carries a lower number.
 *
 * <p>Release is a Lua compare-and-delete so a server can never delete a lease
 * that already expired and was re-acquired by someone else.
 */
public final class RedisLeaseStore implements LeaseStore {
    private static final String LOCK_PREFIX = "swoft:lease:";
    private static final String GENERATION_PREFIX = "swoft:leasegen:";

    /** Delete the lock only when it is still ours (expired-then-stolen safety). */
    private static final String RELEASE_SCRIPT =
            "if redis.call('get', KEYS[1]) == ARGV[1] "
            + "then return redis.call('del', KEYS[1]) else return 0 end";

    /** Extend the ttl only when the lock is still ours. */
    private static final String RENEW_SCRIPT =
            "if redis.call('get', KEYS[1]) == ARGV[1] "
            + "then return redis.call('pexpire', KEYS[1], ARGV[2]) else return 0 end";

    private final RedisConnection connection;

    public RedisLeaseStore(RedisConnection connection) {
        this.connection = connection;
    }

    @Override
    public synchronized Lease acquire(String key, String owner, long ttlMillis) {
        String lock = LOCK_PREFIX + key;
        try {
            Object result = call("SET", lock, owner, "NX", "PX", String.valueOf(ttlMillis));
            if (result == null) {
                // held by someone: re-acquiring our OWN lease is legitimate (a
                // reconnect on the same server, or a renew that raced) - anything
                // else is the handoff barrier and must fail.
                Object current = call("GET", lock);
                if (!owner.equals(current)) {
                    return null;
                }
                call("PEXPIRE", lock, String.valueOf(ttlMillis));
                return new Lease(key, owner, currentGeneration(key),
                        System.currentTimeMillis() + ttlMillis);
            }
            Object generation = call("INCR", GENERATION_PREFIX + key);
            long stamp = generation instanceof Long value ? value : 1L;
            return new Lease(key, owner, stamp, System.currentTimeMillis() + ttlMillis);
        } catch (IOException e) {
            System.err.println("[persist] redis lease acquire failed for '" + key
                    + "': " + e.getMessage());
            return null;
        }
    }

    @Override
    public synchronized Lease peek(String key) {
        try {
            Object owner = call("GET", LOCK_PREFIX + key);
            if (owner == null) {
                return null;
            }
            Object ttl = call("PTTL", LOCK_PREFIX + key);
            long remaining = ttl instanceof Long value && value > 0 ? value : 0L;
            return new Lease(key, String.valueOf(owner), currentGeneration(key),
                    System.currentTimeMillis() + remaining);
        } catch (IOException e) {
            // an unreachable coordinator is NOT an unheld subject
            throw new LeaseStoreException("redis lease read failed for '" + key
                    + "': " + e.getMessage(), e);
        }
    }

    @Override
    public synchronized boolean renew(String key, String owner, long ttlMillis) {
        try {
            // the script returns 1 when the lock was still ours and got extended,
            // 0 when it is gone or belongs to someone else
            Object result = call("EVAL", RENEW_SCRIPT, "1", LOCK_PREFIX + key, owner,
                    String.valueOf(ttlMillis));
            return !(result instanceof Long value) || value != 0L;
        } catch (IOException e) {
            System.err.println("[persist] redis lease renew failed for '" + key
                    + "': " + e.getMessage());
            return true;
        }
    }

    @Override
    public synchronized void release(String key, String owner) {
        try {
            call("EVAL", RELEASE_SCRIPT, "1", LOCK_PREFIX + key, owner);
        } catch (IOException e) {
            // the lease still expires by TTL, so a failed release degrades to a
            // delayed handoff rather than a stuck subject - but it is loud.
            System.err.println("[persist] redis lease release failed for '" + key
                    + "': " + e.getMessage() + " - the lease will expire by ttl");
        }
    }

    private long currentGeneration(String key) throws IOException {
        Object generation = call("GET", GENERATION_PREFIX + key);
        if (generation == null) {
            return 0L;
        }
        try {
            return Long.parseLong(String.valueOf(generation));
        } catch (NumberFormatException e) {
            return 0L;
        }
    }

    /** One command, with a single reconnect-and-retry on a dropped socket. */
    private Object call(String... args) throws IOException {
        try {
            return connection.command(args);
        } catch (IOException first) {
            connection.reconnect();
            return connection.command(args);
        }
    }

    @Override
    public void close() {
        connection.close();
    }
}
