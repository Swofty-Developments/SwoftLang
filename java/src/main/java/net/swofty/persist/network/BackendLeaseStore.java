package net.swofty.persist.network;

import java.util.concurrent.ThreadLocalRandom;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import net.swofty.persist.SwoftStorage;

/**
 * The default lease store (design 1.10.0 §1: "defaults to a lease table in
 * {@code backend}"): reserved rows of the shared backend act as ownership
 * records, so a network deployment needs nothing beyond the mysql/mongodb it
 * already has.
 *
 * <p><b>The barrier is a compare-and-set, not a read-back.</b> "Read, check that
 * it is free, write mine, read it back" looks like it works and does not: two
 * servers can both read free, both write, and both read back their own write if
 * the second write lands after the first read-back. That grants ONE player to
 * TWO servers — the §0 desync, with no guard left downstream. So every state
 * transition here goes through {@link SwoftStorage#compareAndSet}, which the
 * shared backends implement as a genuine single-row conditional write:
 * <ul>
 *   <li><b>acquire a free subject</b> — CAS from ABSENT to our record; exactly
 *       one racer can win;</li>
 *   <li><b>steal a lapsed one</b> — CAS from the exact expired record we
 *       observed, so a server that acquired in between is never displaced;</li>
 *   <li><b>renew</b> — CAS from our own record to the same record with a later
 *       expiry, so a renewal cannot resurrect a lease we already lost;</li>
 *   <li><b>release</b> — CAS from our own record to ABSENT, so we can never
 *       delete a lease that lapsed and was re-acquired by someone else.</li>
 * </ul>
 *
 * <p>The generation counter lives in its own row and is bumped only by the
 * winner of an acquisition, which is what makes it monotonic across handoffs
 * (§2.1.3) even though releasing removes the lease record itself.
 */
public final class BackendLeaseStore implements LeaseStore {

    /** Reserved variable holding the lease records; shares the persistence namespace. */
    public static final String RESERVED_VAR = "__swoft_leases";

    /** Reserved variable holding the monotonic generation of each subject. */
    public static final String GENERATION_VAR = "__swoft_leasegen";

    private final SwoftStorage storage;

    public BackendLeaseStore(SwoftStorage storage) {
        this.storage = storage;
    }

    @Override
    public Lease acquire(String key, String owner, long ttlMillis) {
        long now = System.currentTimeMillis();
        String observed = readRaw(key);
        Record current = Record.parse(observed);

        if (current != null && owner.equals(current.owner) && current.expires > now) {
            // re-taking our OWN live lease is legitimate (a reconnect, a renewal
            // that raced) and must not bump the generation
            Record renewed = current.withExpiry(now + ttlMillis);
            if (storage.compareAndSet(RESERVED_VAR, key, observed, renewed.text()).swapped()) {
                return new Lease(key, owner, generation(key), renewed.expires);
            }
            return null;
        }
        if (current != null && current.expires > now) {
            // the handoff barrier: someone else holds it and has not lapsed
            return null;
        }

        // free, or lapsed: claim it conditionally on EXACTLY what we observed, so
        // a racer who got there first is never displaced
        Record mine = new Record(owner, now + ttlMillis, token());
        if (!storage.compareAndSet(RESERVED_VAR, key, observed, mine.text()).swapped()) {
            return null;
        }
        return new Lease(key, owner, bumpGeneration(key), mine.expires);
    }

    @Override
    public Lease peek(String key) {
        Record current = Record.parse(readRaw(key));
        if (current == null) {
            // no record: unheld. The generation still stands, so the next
            // acquisition's stamp stays monotonic across the gap.
            return new Lease(key, null, generation(key), 0L);
        }
        return new Lease(key, current.owner, generation(key), current.expires);
    }

    @Override
    public boolean renew(String key, String owner, long ttlMillis) {
        String observed = readRaw(key);
        Record current = Record.parse(observed);
        if (current == null || !owner.equals(current.owner)) {
            // OBSERVED not to be ours any more: the caller must give the session up
            return false;
        }
        // A failed swap means the record moved under us. That is not proof we lost
        // the lease (our own renewal could have raced), so it is not reported as a
        // loss; the next cycle re-reads and settles it.
        storage.compareAndSet(RESERVED_VAR, key, observed,
                current.withExpiry(System.currentTimeMillis() + ttlMillis).text());
        return true;
    }

    @Override
    public void release(String key, String owner) {
        String observed = readRaw(key);
        Record current = Record.parse(observed);
        if (current == null || !owner.equals(current.owner)) {
            return;
        }
        // conditional delete: never remove a lease that lapsed and was re-taken
        storage.compareAndSet(RESERVED_VAR, key, observed, null);
    }

    @Override
    public void close() {
        // the backend is owned by the PersistStore, not by the lease table
    }

    // ------------------------------------------------------------------

    /** The stored record text, or null when the subject is unheld. */
    private String readRaw(String key) {
        JsonElement row;
        try {
            row = storage.load(RESERVED_VAR, key);
        } catch (Exception e) {
            throw new LeaseStoreException("lease table read failed for '" + key
                    + "': " + e.getMessage(), e);
        }
        return row == null || row.isJsonNull() ? null : row.toString();
    }

    /** The subject's current generation; 0 when it was never acquired. */
    private long generation(String key) {
        JsonElement row;
        try {
            row = storage.load(GENERATION_VAR, key);
        } catch (Exception e) {
            throw new LeaseStoreException("lease generation read failed for '" + key
                    + "': " + e.getMessage(), e);
        }
        if (row == null || row.isJsonNull() || !row.isJsonPrimitive()) {
            return 0L;
        }
        try {
            return row.getAsLong();
        } catch (Exception e) {
            return 0L;
        }
    }

    /**
     * Raise the subject's generation. Only the winner of an acquisition calls
     * this, and it retries on contention, so the stamp is strictly increasing
     * across every handoff — which is what lets a late writer's flush be
     * recognised as stale (§2.1.3).
     */
    private long bumpGeneration(String key) {
        for (int attempt = 0; attempt < 16; attempt++) {
            long current = generation(key);
            String expected = current == 0L && rawGeneration(key) == null
                    ? null : String.valueOf(current);
            long next = current + 1;
            if (storage.compareAndSet(GENERATION_VAR, key, expected,
                    String.valueOf(next)).swapped()) {
                return next;
            }
        }
        System.err.println("[persist] could not bump the lease generation for '" + key
                + "' - the handoff proceeds, but a late writer from the previous"
                + " owner will not be recognised by its stamp");
        return generation(key) + 1;
    }

    private String rawGeneration(String key) {
        JsonElement row = storage.load(GENERATION_VAR, key);
        return row == null || row.isJsonNull() ? null : row.toString();
    }

    private static String token() {
        return Long.toHexString(ThreadLocalRandom.current().nextLong());
    }

    /**
     * The ownership record. The random {@code token} makes two servers' records
     * distinguishable even if everything else about them matched, which the
     * backends' read-back-after-conditional-insert relies on to tell a win from
     * someone else's identical write.
     */
    private record Record(String owner, long expires, String token) {

        Record withExpiry(long expires) {
            return new Record(owner, expires, token);
        }

        String text() {
            JsonObject object = new JsonObject();
            object.addProperty("owner", owner);
            object.addProperty("expires", expires);
            object.addProperty("token", token);
            return object.toString();
        }

        static Record parse(String text) {
            if (text == null) {
                return null;
            }
            try {
                JsonElement parsed = JsonParser.parseString(text);
                if (!parsed.isJsonObject()) {
                    return null;
                }
                JsonObject object = parsed.getAsJsonObject();
                if (!object.has("owner") || object.get("owner").isJsonNull()) {
                    return null;
                }
                return new Record(object.get("owner").getAsString(),
                        object.has("expires") ? object.get("expires").getAsLong() : 0L,
                        object.has("token") ? object.get("token").getAsString() : "");
            } catch (Exception e) {
                return null;
            }
        }
    }
}
