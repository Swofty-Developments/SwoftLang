package net.swofty.harness;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.google.gson.JsonElement;
import com.google.gson.JsonNull;
import com.google.gson.JsonParser;
import com.google.gson.JsonPrimitive;

import net.swofty.ASTExecutor;
import net.swofty.compiler.FunctionRegistry;
import net.swofty.compiler.ParsedScript;
import net.swofty.compiler.SwoftFunction;
import net.swofty.compiler.SwoftJsonLoader;
import net.swofty.compiler.SwoftcCompiler;
import net.swofty.model.StorageConfigModel;
import net.swofty.nativebridge.representation.Command;
import net.swofty.persist.PersistStore;
import net.swofty.persist.SwoftStorage;
import net.swofty.persist.network.LeaseManager;
import net.swofty.persist.network.LeaseStore;
import net.swofty.persist.network.BackendLeaseStore;
import net.swofty.persist.network.SessionOwnership;

/**
 * Two-server smoke test for {@code mode: network} (design 1.10.0 §1–§3, §6).
 *
 * <p>This is the proof that the desync §0 describes is actually fixed, and it
 * cannot be shown with one server: it runs TWO complete
 * {@link PersistStore}s — each with its own {@link
 * net.swofty.persist.network.NetworkRuntime}, lease manager, replica and bus
 * subscription, under distinct server identities — against ONE shared backend,
 * and then walks a player between them.
 *
 * <p><b>Substrate.</b> The shared backend is {@link SharedBackend}, an
 * in-process map. Production requires mysql/mongodb (the compiler rejects
 * files/sqlite under {@code mode: network}, and {@code --net-smoke} does not
 * relax that — the fixture below declares a mysql backend and compiles clean).
 * The harness substitutes the storage object afterwards, at the
 * {@link SwoftStorage} seam, so no database daemon is needed while every layer
 * above that seam is the real one: {@link BackendLeaseStore}'s read-check-write
 * -read-back acquisition, {@link net.swofty.persist.network.BackendBusChannel}'s
 * polled ring, {@link net.swofty.persist.network.GlobalReplica}, {@link
 * net.swofty.persist.network.VersionStamps}, and the real
 * {@link SessionOwnership} handoff. The redis coordinator is stripped for the
 * same reason (no daemon), which exercises the backend-table fallback — the
 * path a mysql-only deployment actually takes.
 *
 * <p>Every assertion prints PASS/FAIL and the run exits non-zero on the first
 * failure count &gt; 0.
 */
public final class NetSmoke {

    /** The fixture: the §1 headline property is that this is ordinary script code. */
    private static final String FIXTURE = """
            // --net-smoke fixture. Nothing here is network-specific except the
            // storage block: declarations and statements are byte-identical to
            // what a standalone program would write (design 1.10.0 §1).
            storage {
                backend: mysql { host: "10.0.0.5", port: 3306, database: "net", user: "mc", password: "hunter2" }
                mode: network
                flush: every 30 seconds
                on_handoff_failure: kick "Loading your data - reconnect in a moment"
            }

            // replicated global (§2.2): no 'for', so nobody owns it
            persistent pot: Integer = 0
            persistent announcements: List<String> = []
            persistent leaderboard: Map<String, Integer> = new_map()

            // session-owned (§2.1): keyed by Player / OfflinePlayer
            persistent coins for Player: Integer = 0
            persistent history for OfflinePlayer: List<String> = []

            command "bet" {
                execute {
                    // §3.2 atomic ops - the only writes allowed against a global
                    add 50 to pot
                }
            }

            command "rake" {
                execute {
                    subtract 20 from pot
                    append "a bet was placed" to announcements
                    set leaderboard at "house" to 7
                }
            }
            """;

    private static final String KEY_TRANSFER = "11111111-1111-4111-8111-111111111111";
    private static final String KEY_STUCK = "22222222-2222-4222-8222-222222222222";

    private static int failures;
    private static int checks;

    private NetSmoke() {
    }

    public static int run() throws Exception {
        Path dir = Files.createTempDirectory("swoft-net-smoke");
        Path script = dir.resolve("net_smoke.sw");
        Files.writeString(script, FIXTURE);

        ParsedScript parsed = SwoftJsonLoader.load(SwoftcCompiler.compile(new File(script.toString())));
        FunctionRegistry.clear();
        for (SwoftFunction function : parsed.functions()) {
            FunctionRegistry.register(function);
        }

        StorageConfigModel declared = parsed.storage();
        require("the fixture compiled to mode: network", declared != null && declared.isNetwork());
        require("the compiler kept the configured handoff kick message",
                "Loading your data - reconnect in a moment"
                        .equals(declared.handoffFailureOrDefault().messageOrDefault()));

        // strip the coordinator only: mode, backend kind, flush cadence and the
        // handoff policy all stay exactly as the script declared them
        StorageConfigModel config = new StorageConfigModel(declared.backend(),
                declared.flushTicks(), declared.mode(), declared.handoffFailure(), null);

        SharedBackend shared = new SharedBackend();
        PersistStore a = PersistStore.createIsolated(parsed.persistents(), config, shared, "server-A");
        PersistStore b = PersistStore.createIsolated(parsed.persistents(), config, shared, "server-B");
        try {
            require("A is in network mode", a.isNetwork());
            require("B is in network mode", b.isNetwork());

            sessionHandoff(a, b, shared);
            lateWriterRejected(a, b, shared);
            transferBack(a, b, shared);
            remoteRead(a, b);
            replicatedGlobals(a, b, parsed, shared);
            handoffFailure(a, b);
        } finally {
            PersistStore.swapActive(null);
            a.shutdown();
            b.shutdown();
        }

        System.out.println("[NET] " + (checks - failures) + "/" + checks + " assertion(s) passed");
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // §0/§2.1 - the desync the whole design exists to remove
    // ------------------------------------------------------------------

    private static void sessionHandoff(PersistStore a, PersistStore b, SharedBackend shared) {
        System.out.println("[NET] --- (a) join A, earn, transfer to B ---");
        shared.seed("coins", KEY_TRANSFER, 100);

        require("A acquires the session and loads it",
                SessionOwnership.acquireSession(a, a.network(), KEY_TRANSFER) == null);
        require("A reads the stored 100 on join", eq(a.get("coins", KEY_TRANSFER), 100));

        a.set("coins", KEY_TRANSFER, 150);
        require("A holds 150 in memory after the write", eq(a.get("coins", KEY_TRANSFER), 150));
        require("the 150 is UNFLUSHED - the backend still holds 100",
                eq(shared.raw("coins", KEY_TRANSFER), 100));

        SessionOwnership.releaseSession(a, a.network(), KEY_TRANSFER);
        require("the transfer flushed 150 SYNCHRONOUSLY, not on the next timer tick",
                eq(shared.raw("coins", KEY_TRANSFER), 150));

        require("B acquires the session A released",
                SessionOwnership.acquireSession(b, b.network(), KEY_TRANSFER) == null);
        require("*** B reads 150, NOT the stale 100 - the original desync is fixed ***",
                eq(b.get("coins", KEY_TRANSFER), 150));
    }

    // ------------------------------------------------------------------
    // §2.1.2/§2.1.3 - eviction + the version stamp stop the post-handoff clobber
    // ------------------------------------------------------------------

    private static void lateWriterRejected(PersistStore a, PersistStore b, SharedBackend shared) {
        System.out.println("[NET] --- (b) A must not be able to clobber ---");

        Map<String, Object> rowsOnA = a.dump().getOrDefault("coins", Map.of());
        require("A EVICTED the row on transfer (it is gone from A's cache)",
                !rowsOnA.containsKey(KEY_TRANSFER));
        require("A no longer believes it holds the lease",
                !a.network().leases().holds(KEY_TRANSFER));
        require("A cannot verify a lease it released",
                !a.network().leases().verifyHeld(KEY_TRANSFER));

        // a stray task on A writing after the player left
        a.set("coins", KEY_TRANSFER, 999);
        require("a late A write is REFUSED (backend still 150)",
                eq(shared.raw("coins", KEY_TRANSFER), 150));
        require("the refused write did not resurrect the row in A's cache",
                !a.dump().getOrDefault("coins", Map.of()).containsKey(KEY_TRANSFER));

        // and the flush half: A's crash checkpoint firing after the handoff
        a.flushSession(KEY_TRANSFER);
        a.flush();
        require("A's flush after the handoff writes nothing (backend still 150)",
                eq(shared.raw("coins", KEY_TRANSFER), 150));

        long generationB = b.network().leases().generation(KEY_TRANSFER);
        require("B's lease generation is strictly higher than A's", generationB > 1);

        // the version stamp itself: a write carrying the previous owner's
        // generation loses to the current one (§2.1.3)
        net.swofty.persist.network.VersionStamps stamps =
                new net.swofty.persist.network.VersionStamps();
        stamps.stamp("coins", KEY_TRANSFER, generationB);
        require("a write stamped with A's older generation is REJECTED",
                !stamps.accept("coins", KEY_TRANSFER, generationB - 1));
        require("a write stamped with B's current generation is accepted",
                stamps.accept("coins", KEY_TRANSFER, generationB));
    }

    private static void transferBack(PersistStore a, PersistStore b, SharedBackend shared) {
        System.out.println("[NET] --- (c) B writes 200, transfer back to A ---");
        b.set("coins", KEY_TRANSFER, 200);
        require("B holds 200 in memory", eq(b.get("coins", KEY_TRANSFER), 200));

        SessionOwnership.releaseSession(b, b.network(), KEY_TRANSFER);
        require("B's transfer flushed 200", eq(shared.raw("coins", KEY_TRANSFER), 200));

        require("A re-acquires the session",
                SessionOwnership.acquireSession(a, a.network(), KEY_TRANSFER) == null);
        require("*** A reads 200 - the round trip carried B's write back ***",
                eq(a.get("coins", KEY_TRANSFER), 200));
    }

    // ------------------------------------------------------------------
    // §3.1 - a read of a session this server does not own is IO, not cache
    // ------------------------------------------------------------------

    private static void remoteRead(PersistStore a, PersistStore b) throws Exception {
        System.out.println("[NET] --- (§3.1) remote read ---");
        require("A owns the session, so its read is local and sync",
                !a.isRemoteSession("coins", KEY_TRANSFER));
        require("B does NOT own it, so B's read is remote",
                b.isRemoteSession("coins", KEY_TRANSFER));
        Object remote = b.readRemote("coins", KEY_TRANSFER).get();
        require("B's remote read returns the real 200, not the declared default 0",
                eq(remote, 200));
        require("the remote read did not poison B's cache",
                !b.dump().getOrDefault("coins", Map.of()).containsKey(KEY_TRANSFER));
    }

    // ------------------------------------------------------------------
    // §2.2/§3.2 - replicated globals, driven through real compiled script code
    // ------------------------------------------------------------------

    private static void replicatedGlobals(PersistStore a, PersistStore b, ParsedScript parsed,
            SharedBackend shared) {
        System.out.println("[NET] --- (§2.2) replicated globals ---");

        runCommand(parsed, "bet", a);
        require("'add 50 to pot' on A applied at the BACKEND", eq(shared.raw("pot", ""), 50));
        require("A's own replica reflects it immediately", eq(a.get("pot", ""), 50));
        require("B's replica catches up after a broadcast hop",
                await(() -> eq(b.get("pot", ""), 50)));
        require("both servers read the same pot", eq(a.get("pot", ""), b.get("pot", "")));

        runCommand(parsed, "bet", b);
        require("'add 50 to pot' on B composed with A's write (100 at the backend)",
                eq(shared.raw("pot", ""), 100));
        require("A's replica catches up after a broadcast hop",
                await(() -> eq(a.get("pot", ""), 100)));
        require("both servers still agree", eq(a.get("pot", ""), b.get("pot", "")));

        runCommand(parsed, "rake", a);
        require("'subtract 20 from pot' is atomic too", eq(shared.raw("pot", ""), 80));
        require("'append ... to announcements' stored a list of one",
                await(() -> a.get("announcements", "") instanceof List<?> list && list.size() == 1));
        require("'set leaderboard at \"house\" to 7' stored a per-key map write",
                a.get("leaderboard", "") instanceof net.swofty.runtime.MapValue map
                        && eq(map.get("house"), 7));
        require("B replicates the rake as well", await(() -> eq(b.get("pot", ""), 80)));
    }

    // ------------------------------------------------------------------
    // §2.1.5 - handoff failure: kick, never defaults
    // ------------------------------------------------------------------

    private static void handoffFailure(PersistStore a, PersistStore b) {
        System.out.println("[NET] --- (§2.1.5) stuck lease ---");
        require("B takes the session and never lets go",
                SessionOwnership.acquireSession(b, b.network(), KEY_STUCK) == null);

        String failure = SessionOwnership.acquireSession(a, a.network(), KEY_STUCK);
        require("A's acquire FAILS at the handoff barrier", failure != null);
        require("A loaded NOTHING for the stuck session - no default data served",
                !a.dump().getOrDefault("coins", Map.of()).containsKey(KEY_STUCK));
        require("A never took the lease", !a.network().leases().holds(KEY_STUCK));
        require("the configured on_handoff_failure is a kick",
                "kick".equalsIgnoreCase(a.config().handoffFailureOrDefault().action()));
        require("...with the message the script configured",
                "Loading your data - reconnect in a moment"
                        .equals(a.config().handoffFailureOrDefault().messageOrDefault()));

        // a crashed holder must not strand the session: the TTL frees it
        System.out.println("[NET] --- (§2.1.5) a crashed holder's lease expires ---");
        LeaseStore store = new BackendLeaseStore(new SharedBackend());
        LeaseManager crashed = new LeaseManager(store, "server-crashed", 300L, 200L);
        // the rescuer gives up after 150ms - well inside the crashed holder's
        // 300ms TTL, so the first probe must be refused at the barrier and the
        // second (after the TTL lapses) must be granted on its first try
        LeaseManager rescuer = new LeaseManager(store, "server-rescuer", 30_000L, 150L);
        try {
            long first = crashed.acquire(KEY_STUCK);
            require("the first server takes the lease", first != LeaseManager.NO_LEASE);
            require("a second server is BLOCKED while that lease is live",
                    rescuer.acquire(KEY_STUCK) == LeaseManager.NO_LEASE);
            sleep(500);
            long second = rescuer.acquire(KEY_STUCK);
            require("once the TTL lapses the session is picked up elsewhere",
                    second != LeaseManager.NO_LEASE);
            require("the new generation is strictly higher (the late writer loses)",
                    second > first);
            require("the crashed holder can no longer verify its lease",
                    !crashed.verifyHeld(KEY_STUCK));
        } finally {
            crashed.close();
            rescuer.close();
        }
    }

    // ------------------------------------------------------------------
    // plumbing
    // ------------------------------------------------------------------

    /** Run a compiled command block "on" a given server. */
    private static void runCommand(ParsedScript parsed, String name, PersistStore on) {
        Command command = parsed.commands().stream()
                .filter(c -> c != null && name.equals(c.getName()))
                .findFirst().orElse(null);
        if (command == null || command.getExecuteBlock() == null) {
            require("the fixture declares a '" + name + "' command", false);
            return;
        }
        PersistStore previous = PersistStore.swapActive(on);
        try {
            new ASTExecutor(new ExecHarness.CapturingSender(), new HashMap<>())
                    .execute(command.getExecuteBlock());
        } catch (Exception e) {
            require("running '" + name + "' raised " + e, false);
        } finally {
            PersistStore.swapActive(previous);
        }
    }

    /** Poll a condition until it holds; the bus is polled, so a hop takes a moment. */
    private static boolean await(java.util.function.BooleanSupplier condition) {
        long deadline = System.currentTimeMillis() + 5_000L;
        while (System.currentTimeMillis() < deadline) {
            if (condition.getAsBoolean()) {
                return true;
            }
            sleep(50);
        }
        return condition.getAsBoolean();
    }

    private static void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    /** Compare a script value against an expected number/whatever, numerically when both are numbers. */
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
        System.out.println("[NET] " + (ok ? "PASS" : "FAIL") + "  " + what);
    }

    /**
     * The shared substrate: one in-process backend both servers talk to. Stands
     * in for the mysql/mongodb a real deployment needs, at the {@link
     * SwoftStorage} seam — everything above it (leases, bus, replica, version
     * stamps, session hooks) is production code.
     */
    static final class SharedBackend implements SwoftStorage {
        private final Map<String, Map<String, JsonElement>> tables = new ConcurrentHashMap<>();

        @Override
        public Map<String, JsonElement> loadAll(String var) {
            return new LinkedHashMap<>(tables.getOrDefault(var, Map.of()));
        }

        @Override
        public JsonElement load(String var, String key) {
            Map<String, JsonElement> table = tables.get(var);
            return table == null ? null : table.get(key);
        }

        @Override
        public void writeBatch(String var, Map<String, JsonElement> dirty) {
            tables.computeIfAbsent(var, k -> new ConcurrentHashMap<>()).putAll(dirty);
        }

        /**
         * A GENUINELY atomic conditional write, like the mysql/mongodb this
         * stands in for. The default {@link SwoftStorage#compareAndSet} would be
         * a per-instance {@code synchronized} block, and the two servers here
         * hold two different storage objects — it would serialize nothing and
         * quietly hide the very races the harness exists to provoke.
         */
        @Override
        public CasOutcome compareAndSet(String var, String key, String expected, String next) {
            Map<String, JsonElement> table = tables.computeIfAbsent(var,
                    k -> new ConcurrentHashMap<>());
            JsonElement value = next == null ? JsonNull.INSTANCE : JsonParser.parseString(next);
            if (expected == null) {
                JsonElement raced = table.putIfAbsent(key, value);
                if (raced == null || raced.isJsonNull()) {
                    // absent, or the tombstone a delete leaves behind
                    if (raced != null && !table.replace(key, raced, value)) {
                        return new CasOutcome(false, text(table.get(key)));
                    }
                    return new CasOutcome(true, next);
                }
                return new CasOutcome(false, text(raced));
            }
            JsonElement current = table.get(key);
            if (current != null && expected.equals(current.toString())
                    && table.replace(key, current, value)) {
                return new CasOutcome(true, next);
            }
            return new CasOutcome(false, text(table.get(key)));
        }

        private static String text(JsonElement element) {
            return element == null || element.isJsonNull() ? null : element.toString();
        }

        @Override
        public void close() {
        }

        /** Put a value straight into the backend, behind both servers' backs. */
        void seed(String var, String key, long value) {
            writeBatch(var, Map.of(key, new JsonPrimitive(value)));
        }

        /** What the backend ACTUALLY holds - the ground truth every assertion is against. */
        Object raw(String var, String key) {
            JsonElement element = load(var, key);
            if (element == null || !element.isJsonPrimitive()) {
                return null;
            }
            JsonPrimitive primitive = element.getAsJsonPrimitive();
            return primitive.isNumber() ? primitive.getAsLong() : primitive.getAsString();
        }
    }
}
