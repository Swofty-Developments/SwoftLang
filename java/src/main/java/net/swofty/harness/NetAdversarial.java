package net.swofty.harness;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;

import net.swofty.compiler.FunctionRegistry;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftFunction;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.model.StorageConfigModel;
import net.swofty.persist.PersistStore;
import net.swofty.persist.network.BackendLeaseStore;
import net.swofty.persist.network.LeaseManager;
import net.swofty.persist.network.LeaseStore;
import net.swofty.persist.network.NetMessage;
import net.swofty.persist.network.SessionOwnership;

/**
 * Adversarial probes for {@code mode: network} (design 1.10.0 §1–§3, §6).
 *
 * <p>{@link NetSmoke} proves the happy handoff. This proves the UNHAPPY ones —
 * every interleaving that could still produce the §0 desync — and each probe is
 * written to FAIL loudly if the guard it targets is ever removed:
 * <ol>
 *   <li><b>the clobber</b>: a partitioned owner whose lease lapsed while it still
 *       believes it holds one, firing its crash checkpoint after the new owner
 *       has already loaded;</li>
 *   <li><b>the crashed holder's late write</b>: it comes back and flushes;</li>
 *   <li><b>eviction</b>: nothing survives the handoff that a later flush could
 *       re-write, including a write that lands mid-teardown;</li>
 *   <li><b>lost update</b>: two servers incrementing one global concurrently;</li>
 *   <li><b>broadcast ordering</b>: reordered deliveries and a server's own echo;</li>
 *   <li><b>standalone</b>: the default mode allocates and does nothing new;</li>
 *   <li><b>reload</b>: a rebuild with a player connected keeps the lease, at the
 *       same generation, without a second acquire.</li>
 * </ol>
 */
public final class NetAdversarial {

    private static final String FIXTURE = """
            storage {
                backend: mysql { host: "10.0.0.5", port: 3306, database: "net", user: "mc", password: "hunter2" }
                mode: network
                flush: every 30 seconds
            }

            persistent pot: Integer = 0
            persistent coins for Player: Integer = 0
            """;

    private static final String STANDALONE_FIXTURE = """
            storage {
                backend: files "%s"
                flush: every 10 seconds
            }

            persistent pot: Integer = 0
            persistent coins for Player: Integer = 0
            """;

    private static final String K1 = "aaaaaaaa-1111-4111-8111-aaaaaaaaaaaa";
    private static final String K2 = "bbbbbbbb-2222-4222-8222-bbbbbbbbbbbb";
    private static final String K3 = "cccccccc-3333-4333-8333-cccccccccccc";

    private static int failures;
    private static int checks;

    private NetAdversarial() {
    }

    public static int run() throws Exception {
        Path dir = Files.createTempDirectory("swoft-net-adversarial");
        Path script = dir.resolve("net_adversarial.sw");
        Files.writeString(script, FIXTURE);

        ParsedScript parsed =
                SwoftJsonLoader.load(SwoftcCompiler.compile(new File(script.toString())));
        FunctionRegistry.clear();
        for (SwoftFunction function : parsed.functions()) {
            FunctionRegistry.register(function);
        }
        StorageConfigModel declared = parsed.storage();
        StorageConfigModel config = new StorageConfigModel(declared.backend(),
                declared.flushTicks(), declared.mode(), declared.handoffFailure(), null);

        NetSmoke.SharedBackend shared = new NetSmoke.SharedBackend();
        PersistStore a = PersistStore.createIsolated(parsed.persistents(), config, shared, "adv-A");
        PersistStore b = PersistStore.createIsolated(parsed.persistents(), config, shared, "adv-B");
        try {
            probeClobberAfterLeaseLapse(a, b, shared);
            probeCrashedHolderReturns(a, b, shared);
            probeEvictionWindow(a, shared);
            probeLostUpdate(a, b, shared);
            probeBroadcastOrdering(a, b);
            probeReloadWithSession(a, b);
            probeConcurrentAcquire();
        } finally {
            PersistStore.swapActive(null);
            a.shutdown();
            b.shutdown();
        }

        probeStandaloneUntouched(dir);

        System.out.println("[ADV] " + (checks - failures) + "/" + checks + " assertion(s) passed");
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // (1) THE CLOBBER. A's lease lapses (a long GC pause, a network partition)
    // while A still has unflushed rows and still BELIEVES it is the owner. B
    // legitimately picks the session up. A then wakes and fires its crash
    // checkpoint. Nothing A does from here may reach the backend.
    // ------------------------------------------------------------------

    private static void probeClobberAfterLeaseLapse(PersistStore a, PersistStore b,
            NetSmoke.SharedBackend shared) {
        System.out.println("[ADV] --- (1) partitioned owner cannot clobber the new one ---");
        shared.seed("coins", K1, 100);

        require("A acquires and loads", SessionOwnership.acquireSession(a, a.network(), K1) == null);
        a.set("coins", K1, 500);
        require("A holds 500 unflushed", eq(shared.raw("coins", K1), 100));

        // the partition: A's lease expires at the store without A noticing. renew
        // with a negative ttl writes an already-lapsed expiry for the current
        // holder, which is exactly the state a paused/crashed A leaves behind.
        LeaseStore direct = new BackendLeaseStore(shared);
        direct.renew(K1, "adv-A", -1_000L);
        require("A's lease is expired at the store, but A still believes it holds it",
                a.network().leases().holds(K1));

        require("B takes over the lapsed session",
                SessionOwnership.acquireSession(b, b.network(), K1) == null);
        require("B loaded the DURABLE 100, not A's unflushed 500", eq(b.get("coins", K1), 100));
        b.set("coins", K1, 120);
        SessionOwnership.releaseSession(b, b.network(), K1);
        require("B's own handoff wrote 120", eq(shared.raw("coins", K1), 120));

        // ...and now A wakes up
        a.flush();
        require("*** A's crash checkpoint did NOT clobber (backend still 120) ***",
                eq(shared.raw("coins", K1), 120));
        a.flushSession(K1);
        require("A's synchronous session flush did NOT clobber either",
                eq(shared.raw("coins", K1), 120));
        require("A no longer believes it owns the session it lost",
                !a.network().leases().holds(K1));
        require("A dropped the row it can no longer own",
                !a.dump().getOrDefault("coins", Map.of()).containsKey(K1));
    }

    // ------------------------------------------------------------------
    // (2) The crashed holder RESTARTS and its old lease record is still in the
    // table. Its stale write must lose to the generation stamp.
    // ------------------------------------------------------------------

    private static void probeCrashedHolderReturns(PersistStore a, PersistStore b,
            NetSmoke.SharedBackend shared) {
        System.out.println("[ADV] --- (2) a crashed holder comes back ---");
        shared.seed("coins", K2, 10);

        require("A acquires", SessionOwnership.acquireSession(a, a.network(), K2) == null);
        long generationA = a.network().leases().generation(K2);
        a.set("coins", K2, 999);

        // crash: no release, no flush - just a lapsed lease
        LeaseStore direct = new BackendLeaseStore(shared);
        direct.renew(K2, "adv-A", -1_000L);

        require("B rescues the session after the TTL",
                SessionOwnership.acquireSession(b, b.network(), K2) == null);
        long generationB = b.network().leases().generation(K2);
        require("B's generation is strictly higher than the crashed A's",
                generationB > generationA);
        require("B sees the durable 10, never A's lost 999", eq(b.get("coins", K2), 10));

        b.set("coins", K2, 42);
        SessionOwnership.releaseSession(b, b.network(), K2);
        require("B's write is durable", eq(shared.raw("coins", K2), 42));

        // A's restarted process: re-acquiring is legal and must raise the bar again
        require("A re-acquires after B released",
                SessionOwnership.acquireSession(a, a.network(), K2) == null);
        require("A's new generation beats B's", a.network().leases().generation(K2) > generationB);
        require("A reads B's 42, not the 999 it lost", eq(a.get("coins", K2), 42));
        SessionOwnership.releaseSession(a, a.network(), K2);
    }

    // ------------------------------------------------------------------
    // (3) EVICTION. A write that lands between the evict and the release is the
    // one way a row can come back from the dead - and a later flush would then
    // re-write it under the new owner.
    // ------------------------------------------------------------------

    private static void probeEvictionWindow(PersistStore a, NetSmoke.SharedBackend shared) {
        System.out.println("[ADV] --- (3) nothing survives the teardown ---");
        shared.seed("coins", K3, 7);
        require("A acquires", SessionOwnership.acquireSession(a, a.network(), K3) == null);
        a.set("coins", K3, 8);

        // hand-driven teardown so the write lands in the evict -> release window
        a.flushSession(K3);
        a.evictSession(K3);
        a.set("coins", K3, 4242);
        a.network().leases().release(K3);

        require("no row survives the release",
                !a.dump().getOrDefault("coins", Map.of()).containsKey(K3));
        require("no version stamp survives the release",
                a.network().versions().current("coins", K3) == 0L);
        a.flush();
        require("*** a later flush cannot re-write the evicted row (backend still 8) ***",
                eq(shared.raw("coins", K3), 8));
    }

    // ------------------------------------------------------------------
    // (4) LOST UPDATE. Two servers running 'add 1 to pot' concurrently. The
    // total must be exact: the op has to be atomic at the backend, not a
    // read-modify-write racing in two JVMs.
    // ------------------------------------------------------------------

    private static void probeLostUpdate(PersistStore a, PersistStore b,
            NetSmoke.SharedBackend shared) throws Exception {
        System.out.println("[ADV] --- (4) concurrent 'add' on two servers ---");
        int rounds = 250;
        CountDownLatch start = new CountDownLatch(1);
        Thread left = adder(a, rounds, start);
        Thread right = adder(b, rounds, start);
        start.countDown();
        left.join();
        right.join();

        Object total = shared.raw("pot", "");
        require("*** 2x" + rounds + " atomic adds total exactly " + (2 * rounds)
                + " (got " + total + ") ***", eq(total, 2 * rounds));
    }

    private static Thread adder(PersistStore store, int rounds, CountDownLatch start) {
        Thread thread = new Thread(() -> {
            try {
                start.await();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            }
            for (int i = 0; i < rounds; i++) {
                store.atomic("add", "pot", "", 1, null);
            }
        });
        thread.start();
        return thread;
    }

    // ------------------------------------------------------------------
    // (5) BROADCAST. A reordered delivery must not roll a replica backwards, and
    // a server must ignore the echo of its own write (§5.4).
    // ------------------------------------------------------------------

    private static void probeBroadcastOrdering(PersistStore a, PersistStore b) {
        System.out.println("[ADV] --- (5) reordered broadcasts and self-echo ---");
        long base = System.currentTimeMillis() + 1_000_000L;

        b.network().replica().applyRemote(
                NetMessage.value("pot", "", PersistStore.encodeRaw(900), "adv-C", base + 20));
        require("the newer broadcast applied", eq(b.get("pot", ""), 900));

        b.network().replica().applyRemote(
                NetMessage.value("pot", "", PersistStore.encodeRaw(800), "adv-C", base + 10));
        require("*** an out-of-order older broadcast is DROPPED (still 900) ***",
                eq(b.get("pot", ""), 900));

        b.network().replica().applyRemote(
                NetMessage.value("pot", "", PersistStore.encodeRaw(950), "adv-C", base + 30));
        require("a later broadcast still applies - converged on the newest", eq(b.get("pot", ""), 950));

        Object before = a.get("pot", "");
        a.network().replica().applyRemote(
                NetMessage.value("pot", "", PersistStore.encodeRaw(-1), "adv-A", base + 99));
        require("a server IGNORES the echo of its own broadcast", eq(a.get("pot", ""), before));
    }

    // ------------------------------------------------------------------
    // (6) STANDALONE. The default mode must allocate no network machinery, keep
    // the eager whole-table load, and never touch the lease table.
    // ------------------------------------------------------------------

    private static void probeStandaloneUntouched(Path dir) throws Exception {
        System.out.println("[ADV] --- (6) mode: standalone is untouched ---");
        Path data = dir.resolve("standalone-data");
        Path script = dir.resolve("standalone.sw");
        Files.writeString(script, String.format(STANDALONE_FIXTURE,
                data.toString().replace("\\", "\\\\")));
        ParsedScript parsed =
                SwoftJsonLoader.load(SwoftcCompiler.compile(new File(script.toString())));
        StorageConfigModel config = parsed.storage();
        require("a storage block with no 'mode:' is standalone", !config.isNetwork());

        PersistStore store = PersistStore.createIsolated(parsed.persistents(), config,
                PersistStore.createBackend(config.backend()), "standalone");
        try {
            require("no network runtime is allocated", store.network() == null);
            require("isNetwork() is false", !store.isNetwork());

            // write-behind, exactly as before: set is in-memory, flush persists
            store.set("coins", K1, 77);
            require("a standalone per-player write is a plain sync cache write",
                    eq(store.get("coins", K1), 77));
            store.set("pot", "", 5);
            require("a standalone global write is a plain sync cache write",
                    eq(store.get("pot", ""), 5));
            store.flush();
        } finally {
            store.shutdown();
        }

        // the sidecar layout of an unchanged program must be unchanged: only the
        // program's own variables, no lease table, no bus ring
        List<String> written = Files.list(data).map(p -> p.getFileName().toString()).sorted()
                .toList();
        require("standalone wrote only the program's own variables (got " + written + ")",
                written.equals(List.of("coins.json", "pot.json")));

        // re-open: the standalone store eagerly loads EVERY row of a per-player
        // variable at boot (network mode deliberately does not - §2.3)
        PersistStore reopened = PersistStore.createIsolated(parsed.persistents(), config,
                PersistStore.createBackend(config.backend()), "standalone");
        try {
            require("standalone eagerly loaded the per-player row at boot",
                    reopened.dump().getOrDefault("coins", Map.of()).containsKey(K1));
            require("...with the value it stored", eq(reopened.get("coins", K1), 77));
            require("a standalone read of a row nobody 'owns' is still a plain sync read",
                    !reopened.isRemoteSession("coins", K1));
        } finally {
            reopened.shutdown();
        }
    }

    // ------------------------------------------------------------------
    // (7) RELOAD with a player connected (§6): the lease survives, at the SAME
    // generation (a re-acquire would be a second handoff for a player who never
    // left), and no other server can slip in during the rebuild.
    // ------------------------------------------------------------------

    private static void probeReloadWithSession(PersistStore a, PersistStore b) {
        System.out.println("[ADV] --- (7) hot reload with a live session ---");
        String key = "dddddddd-4444-4444-8444-dddddddddddd";
        require("A acquires", SessionOwnership.acquireSession(a, a.network(), key) == null);
        long generation = a.network().leases().generation(key);
        a.set("coins", key, 64);

        a.network().onReload();
        a.network().onReload();

        require("the lease survived the reload", a.network().leases().holds(key));
        require("...at the SAME generation - no double acquire",
                a.network().leases().generation(key) == generation);
        require("...and is still verifiable at the store", a.network().leases().verifyHeld(key));
        require("the in-memory row survived the reload", eq(a.get("coins", key), 64));

        LeaseManager other = b.network().leases();
        require("another server sees the session as live-held across the reload",
                other.heldElsewhere(key));

        SessionOwnership.releaseSession(a, a.network(), key);
    }

    // ------------------------------------------------------------------
    // (8) THE HANDOFF BARRIER ITSELF. Two servers racing to acquire the same
    // fresh subject: at most ONE may be granted. A double grant is two owners
    // for one player, which is the §0 desync with no guard left downstream.
    // ------------------------------------------------------------------

    private static void probeConcurrentAcquire() throws Exception {
        System.out.println("[ADV] --- (8) two servers race for one session ---");
        int rounds = 400;
        NetSmoke.SharedBackend shared = new NetSmoke.SharedBackend();
        LeaseStore left = new BackendLeaseStore(shared);
        LeaseStore right = new BackendLeaseStore(shared);
        java.util.concurrent.atomic.AtomicInteger doubleGrants =
                new java.util.concurrent.atomic.AtomicInteger();
        java.util.concurrent.atomic.AtomicInteger noGrants =
                new java.util.concurrent.atomic.AtomicInteger();

        for (int round = 0; round < rounds; round++) {
            String key = "race-" + round;
            CountDownLatch start = new CountDownLatch(1);
            boolean[] granted = new boolean[2];
            Thread one = racer(left, "race-A", key, start, granted, 0);
            Thread two = racer(right, "race-B", key, start, granted, 1);
            start.countDown();
            one.join();
            two.join();
            if (granted[0] && granted[1]) {
                doubleGrants.incrementAndGet();
            } else if (!granted[0] && !granted[1]) {
                noGrants.incrementAndGet();
            }
        }
        require("*** no subject was granted to TWO servers at once (got "
                + doubleGrants.get() + " double grants in " + rounds + " races) ***",
                doubleGrants.get() == 0);
        require("the barrier is not simply refusing everyone (" + noGrants.get()
                + "/" + rounds + " races granted nobody)", noGrants.get() < rounds / 4);
    }

    private static Thread racer(LeaseStore store, String owner, String key,
            CountDownLatch start, boolean[] granted, int slot) {
        Thread thread = new Thread(() -> {
            try {
                start.await();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                return;
            }
            granted[slot] = store.acquire(key, owner, 30_000L) != null;
        });
        thread.start();
        return thread;
    }

    // ------------------------------------------------------------------

    private static boolean eq(Object actual, Object expected) {
        if (actual instanceof Number left && expected instanceof Number right) {
            return left.doubleValue() == right.doubleValue();
        }
        return actual != null && actual.equals(expected);
    }

    private static void require(String what, boolean ok) {
        checks++;
        if (!ok) {
            failures++;
        }
        System.out.println("[ADV] " + (ok ? "PASS" : "FAIL") + "  " + what);
    }
}
