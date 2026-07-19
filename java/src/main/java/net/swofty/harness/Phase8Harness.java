package net.swofty.harness;

import java.nio.file.Files;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import net.swofty.ASTExecutor;
import net.swofty.fishing.FishingLootRegistry;
import net.swofty.fishing.FishingMedium;
import net.swofty.fishing.FishingRuntime;
import net.swofty.model.FishingLootEntryModel;
import net.swofty.model.FishingLootModel;
import net.swofty.model.PersistentDeclModel;
import net.swofty.model.ServerConfigModel;
import net.swofty.model.StorageBackendModel;
import net.swofty.model.StorageConfigModel;
import net.swofty.nativebridge.execution.commands.PersistSetStatement;
import net.swofty.nativebridge.execution.expressions.NumberLiteral;
import net.swofty.nativebridge.execution.expressions.PersistGetExpression;
import net.swofty.nativebridge.execution.expressions.VariableReference;
import net.swofty.nativebridge.representation.BaseType;
import net.swofty.nativebridge.representation.DataType;
import net.swofty.persist.PersistStore;
import net.swofty.players.OfflinePlayerValue;
import net.swofty.players.SeenPlayersStore;
import net.swofty.props.NoneValue;
import net.swofty.props.PathResolver;
import net.swofty.props.PropertyRegistry;
import net.swofty.props.PropertyTables;
import net.swofty.runtime.ExecutionContext;
import net.swofty.runtime.SystemSender;
import net.swofty.runtime.Values;

/**
 * --phase8-checks: serverless proofs for phase 8. Seen-store roundtrip
 * through a real files backend (seeded fake entries, flush + reload),
 * the offline persistence bridge (Player-uuid subject writes read back
 * through an OfflinePlayer subject with the same uuid, and vice versa),
 * the weighted loot roll distribution over 10k rolls, and the bite
 * window bounds.
 */
public final class Phase8Harness {

    private Phase8Harness() {
    }

    public static int run() throws Exception {
        PropertyTables.ensureRegistered();
        int failures = 0;
        failures += seenStoreChecks();
        failures += livePlayerRowChecks();
        failures += byNameDisambiguationChecks();
        failures += offlineBridgeChecks();
        failures += reservedVarChecks();
        failures += lootDistributionChecks();
        failures += biteWindowChecks();
        System.out.println("[PHASE8] " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures == 0 ? 0 : 1;
    }

    // ------------------------------------------------------------------
    // seen-store roundtrip (serverless, real files backend)
    // ------------------------------------------------------------------

    private static int seenStoreChecks() throws Exception {
        int failures = 0;
        String dir = Files.createTempDirectory("swoft-phase8-seen").toString();
        StorageConfigModel config = new StorageConfigModel(
                StorageBackendModel.files(dir), StorageConfigModel.DEFAULT_FLUSH_TICKS);

        String uuidAlice = "00000000-0000-0000-0000-0000000000aa";
        String uuidBob = "00000000-0000-0000-0000-0000000000bb";
        String uuidCarol = "00000000-0000-0000-0000-0000000000cc";

        SeenPlayersStore.initialize(config);
        SeenPlayersStore.recordJoin(java.util.UUID.fromString(uuidAlice), "Alice");
        SeenPlayersStore.recordJoin(java.util.UUID.fromString(uuidBob), "Bob");
        SeenPlayersStore.recordQuit(java.util.UUID.fromString(uuidBob), "Bob");
        SeenPlayersStore.seed(uuidCarol, "Carol"); // fetched-style, never played

        // case-insensitive name lookup
        OfflinePlayerValue alice = SeenPlayersStore.byName("aLiCe");
        failures += expect("byName case-insensitive", true,
                alice != null && alice.uuid().equals(uuidAlice));
        failures += expect("byName miss is null", true,
                SeenPlayersStore.byName("nobody") == null);

        // builtins through the execution context
        Map<String, Object> vars = new HashMap<>();
        ExecutionContext context = new ASTExecutor(SystemSender.INSTANCE, vars).context();
        Object viaBuiltin = context.callFunction("offline_player",
                List.of(new net.swofty.nativebridge.execution.expressions.StringLiteral(
                        "alice")));
        failures += expect("offline_player builtin", true,
                viaBuiltin instanceof OfflinePlayerValue found
                        && found.uuid().equals(uuidAlice));
        Object viaUuid = context.callFunction("offline_player_uuid",
                List.of(new net.swofty.nativebridge.execution.expressions.StringLiteral(
                        uuidBob)));
        failures += expect("offline_player_uuid builtin resolves name", "Bob",
                viaUuid instanceof OfflinePlayerValue found ? found.name() : viaUuid);
        Object unknown = context.callFunction("offline_player_uuid",
                List.of(new net.swofty.nativebridge.execution.expressions.StringLiteral(
                        "00000000-0000-0000-0000-0000000000dd")));
        failures += expect("offline_player_uuid is total", "unknown",
                unknown instanceof OfflinePlayerValue found ? found.name() : unknown);
        Object all = context.callFunction("all_seen_players", List.of());
        failures += expect("all_seen_players size", 3,
                all instanceof List<?> list ? list.size() : all);

        // property rows (PathResolver, same machinery scripts use)
        failures += expect("name row", "Alice",
                PathResolver.getProperty(alice, "name", 0, 0));
        failures += expect("uuid row", uuidAlice,
                PathResolver.getProperty(alice, "uuid", 0, 0));
        failures += expect("online row false serverless", false,
                PathResolver.getProperty(alice, "online", 0, 0));
        failures += expect("player row none when offline", NoneValue.INSTANCE,
                PathResolver.getProperty(alice, "player", 0, 0));
        failures += expect("has_played_before tracked join", true,
                PathResolver.getProperty(alice, "has_played_before", 0, 0));
        OfflinePlayerValue carol = SeenPlayersStore.byName("Carol");
        failures += expect("has_played_before false for fetched-only", false,
                PathResolver.getProperty(carol, "has_played_before", 0, 0));
        failures += expect("first_seen unknown pre-tracking", "unknown",
                PathResolver.getProperty(carol, "first_seen", 0, 0));
        Object firstSeen = PathResolver.getProperty(alice, "first_seen", 0, 0);
        failures += expect("first_seen is an ISO timestamp", true,
                firstSeen instanceof String s && s.contains("T"));
        Object lastSeen = PathResolver.getProperty(alice, "last_seen", 0, 0);
        failures += expect("last_seen is an ISO timestamp", true,
                lastSeen instanceof String s && s.contains("T"));

        // subtype semantics at the runtime level
        failures += expect("is a OfflinePlayer for offline value", true,
                Values.isType(alice, "OfflinePlayer"));
        failures += expect("is a Player stays false for pure-offline", false,
                Values.isType(alice, "Player"));
        failures += expect("displayString is the name", "Alice",
                Values.displayString(alice));

        // roundtrip: flush + close, reload from the backend alone
        SeenPlayersStore.shutdownActive();
        SeenPlayersStore.clearMemory();
        failures += expect("memory cleared between rounds", 0, SeenPlayersStore.size());
        SeenPlayersStore.initialize(config);
        failures += expect("roundtrip size", 3, SeenPlayersStore.size());
        OfflinePlayerValue reloaded = SeenPlayersStore.byName("Alice");
        failures += expect("roundtrip identity", true,
                reloaded != null && reloaded.uuid().equals(uuidAlice));
        failures += expect("roundtrip first_seen survived", firstSeen,
                PathResolver.getProperty(reloaded, "first_seen", 0, 0));
        failures += expect("roundtrip pre-tracking stays unknown", "unknown",
                PathResolver.getProperty(SeenPlayersStore.byName("Carol"),
                        "first_seen", 0, 0));
        SeenPlayersStore.shutdownActive();
        SeenPlayersStore.clearMemory();

        System.out.println("[PHASE8] seen-store roundtrip: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // OfflinePlayer rows on live Player values (checker composition:
    // props_of_ty TPlayer = player_props @ offline_extra_props, so the
    // runtime table must resolve every row on a Player-classed owner)
    // ------------------------------------------------------------------

    private static int livePlayerRowChecks() {
        int failures = 0;
        for (String row : new String[] { "name", "uuid", "online", "player",
                "first_seen", "last_seen", "has_played_before" }) {
            failures += expect("Player." + row + " resolvable", true,
                    PropertyRegistry.lookup(net.minestom.server.entity.Player.class, row)
                            .isPresent());
        }
        System.out.println("[PHASE8] live-player offline rows: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // byName disambiguation: after a Mojang rename a stale row can share
    // the name with the current owner; the most recently seen row wins
    // ------------------------------------------------------------------

    private static int byNameDisambiguationChecks() throws Exception {
        int failures = 0;
        String staleHolder = "00000000-0000-0000-0000-0000000000aa";
        String currentHolder = "00000000-0000-0000-0000-0000000000bb";

        // explicit timestamps: the later last_seen wins regardless of map order
        SeenPlayersStore.clearMemory();
        SeenPlayersStore.seedFull(staleHolder, "Bob",
                "2026-01-01T00:00:00Z", "2026-01-02T00:00:00Z");
        SeenPlayersStore.seedFull(currentHolder, "Bob",
                "2026-03-01T00:00:00Z", "2026-03-02T00:00:00Z");
        OfflinePlayerValue hit = SeenPlayersStore.byName("bob");
        failures += expect("latest last_seen wins the shared name", currentHolder,
                hit != null ? hit.uuid() : null);

        // a tracked row beats a fetched-only row (null timestamps oldest)
        SeenPlayersStore.clearMemory();
        SeenPlayersStore.seed(staleHolder, "Ann"); // Mojang fetch, never played
        SeenPlayersStore.seedFull(currentHolder, "Ann",
                "2026-01-01T00:00:00Z", "2026-01-02T00:00:00Z");
        hit = SeenPlayersStore.byName("ann");
        failures += expect("tracked row beats fetched-only row", currentHolder,
                hit != null ? hit.uuid() : null);

        // the live rename-shadow flow: old holder joins+quits as Bob, then a
        // different account owning the name joins — the new joiner wins
        SeenPlayersStore.clearMemory();
        SeenPlayersStore.recordJoin(java.util.UUID.fromString(staleHolder), "Bob");
        SeenPlayersStore.recordQuit(java.util.UUID.fromString(staleHolder), "Bob");
        Thread.sleep(5); // guarantee a strictly later last_seen stamp
        SeenPlayersStore.recordJoin(java.util.UUID.fromString(currentHolder), "Bob");
        hit = SeenPlayersStore.byName("bob");
        failures += expect("rename-shadow: current name owner wins", currentHolder,
                hit != null ? hit.uuid() : null);
        SeenPlayersStore.clearMemory();

        System.out.println("[PHASE8] byName disambiguation: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // offline persistence bridge (uuid keying both ways)
    // ------------------------------------------------------------------

    private static int offlineBridgeChecks() throws Exception {
        int failures = 0;
        String uuid = "12345678-1234-1234-1234-123456789abc";
        StorageConfigModel config = new StorageConfigModel(
                StorageBackendModel.files(
                        Files.createTempDirectory("swoft-phase8-persist").toString()),
                StorageConfigModel.DEFAULT_FLUSH_TICKS);
        PersistentDeclModel decl = new PersistentDeclModel("kills",
                new DataType(BaseType.PLAYER), new DataType(BaseType.INTEGER),
                new NumberLiteral(0, true), -1, -1);
        PersistStore store = PersistStore.initialize(List.of(decl), config);

        Map<String, Object> vars = new HashMap<>();
        vars.put("op", new OfflinePlayerValue(uuid, "Steve"));
        ExecutionContext context = new ASTExecutor(SystemSender.INSTANCE, vars).context();

        // an OfflinePlayer subject keys by the exact uuid string a Player
        // subject would produce
        failures += expect("persistKey(OfflinePlayer) is the uuid", uuid,
                context.persistKey("kills", new VariableReference("op")));

        // write via the Player-uuid subject key, read via the OfflinePlayer
        // subject (script-level persist_get) - one row, both spellings
        store.set("kills", uuid, 7);
        Object read = new PersistGetExpression("kills",
                new VariableReference("op")).evaluate(context);
        failures += expect("Player-keyed write reads via OfflinePlayer subject", 7, read);

        // and the reverse: script-level persist_set through the
        // OfflinePlayer subject lands on the same uuid row
        new PersistSetStatement("kills", new VariableReference("op"),
                new NumberLiteral(9, true)).execute(context);
        failures += expect("OfflinePlayer-keyed write lands on the uuid row", 9,
                store.get("kills", uuid));

        // default still serves other subjects
        failures += expect("unrelated subject sees the default", 0,
                store.get("kills", "99999999-9999-9999-9999-999999999999"));

        PersistStore.shutdownActive();
        System.out.println("[PHASE8] offline persistence bridge: "
                + (failures == 0 ? "PASS" : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // reserved-var defense: a persistent decl named like the seen-players
    // store must be rejected (the checker already blocks the '__' prefix;
    // this is the runtime backstop protecting the stored seen rows)
    // ------------------------------------------------------------------

    private static int reservedVarChecks() throws Exception {
        int failures = 0;
        StorageConfigModel config = new StorageConfigModel(
                StorageBackendModel.files(
                        Files.createTempDirectory("swoft-phase8-reserved").toString()),
                StorageConfigModel.DEFAULT_FLUSH_TICKS);
        PersistentDeclModel reserved = new PersistentDeclModel(
                SeenPlayersStore.RESERVED_VAR,
                new DataType(BaseType.PLAYER), new DataType(BaseType.INTEGER),
                new NumberLiteral(0, true), -1, -1);
        boolean threw = false;
        try {
            PersistStore.initialize(List.of(reserved), config);
            PersistStore.shutdownActive();
        } catch (IllegalArgumentException expected) {
            threw = true;
        }
        failures += expect("reserved __seen_players decl rejected", true, threw);
        System.out.println("[PHASE8] reserved-var defense: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // weighted loot roll distribution (10k rolls)
    // ------------------------------------------------------------------

    private static int lootDistributionChecks() {
        int failures = 0;
        FishingLootModel table = FishingLootRegistry.DEFAULT_VANILLA;
        int rolls = 10_000;
        double total = table.entries().stream()
                .mapToDouble(FishingLootEntryModel::weight).sum();

        Map<String, Integer> counts = new HashMap<>();
        for (int i = 0; i < rolls; i++) {
            FishingLootEntryModel entry = FishingLootRegistry.roll(table.entries(),
                    ThreadLocalRandom.current());
            counts.merge(entry.id(), 1, Integer::sum);
        }

        // chi-square-ish sanity: every entry within 4.5 sigma of expected
        // (p(all 8 within 4.5 sigma) is overwhelming; a broken roll is
        // orders of magnitude off)
        for (FishingLootEntryModel entry : table.entries()) {
            double p = entry.weight() / total;
            double expected = rolls * p;
            double sigma = Math.sqrt(rolls * p * (1 - p));
            int observed = counts.getOrDefault(entry.id(), 0);
            if (Math.abs(observed - expected) > 4.5 * sigma) {
                System.err.println("[PHASE8] FAIL loot roll for " + entry.id()
                        + ": observed " + observed + ", expected " + expected
                        + " +- " + (4.5 * sigma));
                failures++;
            }
        }
        failures += expect("every entry was rolled at least once",
                table.entries().size(), counts.size());

        // table matching: world-specific beats generic, miss falls back
        FishingLootRegistry.clear();
        FishingLootModel generic = new FishingLootModel("lava_generic", "lava", null,
                List.of(new FishingLootEntryModel("item", "MAGMA_CREAM", 1, null)), -1, -1);
        FishingLootModel specific = new FishingLootModel("lava_nether", "lava", "nether",
                List.of(new FishingLootEntryModel("item", "BLAZE_POWDER", 1, null)), -1, -1);
        FishingLootRegistry.register(generic);
        FishingLootRegistry.register(specific);
        failures += expect("world-specific table wins", "lava_nether",
                FishingLootRegistry.match(FishingMedium.LAVA, "nether").name());
        failures += expect("generic table for other worlds", "lava_generic",
                FishingLootRegistry.match(FishingMedium.LAVA, "world").name());
        failures += expect("no match falls back to vanilla", "__vanilla",
                FishingLootRegistry.match(FishingMedium.WATER, "world").name());
        FishingLootRegistry.clear();

        System.out.println("[PHASE8] loot distribution: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    // ------------------------------------------------------------------
    // bite window bounds
    // ------------------------------------------------------------------

    private static int biteWindowChecks() {
        int failures = 0;
        int min = ServerConfigModel.DEFAULT_FISHING_MIN_BITE_TICKS;
        int max = ServerConfigModel.DEFAULT_FISHING_MAX_BITE_TICKS;
        failures += expect("default min bite is 5s", 100, min);
        failures += expect("default max bite is 30s", 600, max);

        boolean sawLowHalf = false;
        boolean sawHighHalf = false;
        for (int i = 0; i < 2_000; i++) {
            long delay = FishingRuntime.rollBiteDelayTicks(min, max);
            if (delay < min || delay > max) {
                System.err.println("[PHASE8] FAIL bite delay " + delay
                        + " outside [" + min + ", " + max + "]");
                failures++;
                break;
            }
            if (delay < (min + max) / 2) {
                sawLowHalf = true;
            } else {
                sawHighHalf = true;
            }
        }
        failures += expect("bite delays spread across the window", true,
                sawLowHalf && sawHighHalf);
        failures += expect("degenerate window is exact", 42L,
                FishingRuntime.rollBiteDelayTicks(42, 42));

        // the config plumbing clamps and swaps a backwards window
        FishingRuntime.configure(new ServerConfigModel("offline", null, "0.0.0.0",
                25565, null, null, null, -1, "127.0.0.1", null, false, 400, 200));
        failures += expect("backwards window swapped (min)", 200,
                FishingRuntime.minBiteTicks());
        failures += expect("backwards window swapped (max)", 400,
                FishingRuntime.maxBiteTicks());
        FishingRuntime.configure(null);
        failures += expect("null config restores defaults", 100,
                FishingRuntime.minBiteTicks());

        System.out.println("[PHASE8] bite window: " + (failures == 0 ? "PASS"
                : failures + " failure(s)"));
        return failures;
    }

    private static int expect(String what, Object expected, Object actual) {
        if (expected.equals(actual)) {
            return 0;
        }
        System.err.println("[PHASE8] FAIL " + what + ": expected " + expected
                + ", got " + actual);
        return 1;
    }
}
