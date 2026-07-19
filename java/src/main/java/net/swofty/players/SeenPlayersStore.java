package net.swofty.players;

import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import net.swofty.model.StorageConfigModel;
import net.swofty.persist.PersistStore;
import net.swofty.persist.SwoftStorage;

/**
 * Every player the server has ever seen (phase 8), riding the configured
 * SwoftStorage backend as the reserved variable "__seen_players": key =
 * uuid string, value = {name, first_seen, last_seen}. Join/quit listeners
 * (PlayersRuntime) update names and timestamps; writes are write-behind
 * like other persist vars (dirty rows, periodic flush loop, final flush
 * on shutdown), so the data survives a backend switch like any persist
 * data. The store also works without a backend (harness/serverless):
 * entries live in memory and flushes are no-ops until initialize() runs.
 */
public final class SeenPlayersStore {
    public static final String RESERVED_VAR = "__seen_players";

    /** One seen-store row; null timestamps mean pre-tracking ("unknown"). */
    public record Entry(String name, String firstSeen, String lastSeen) {
    }

    private static final ConcurrentHashMap<String, Entry> ENTRIES = new ConcurrentHashMap<>();
    private static final Set<String> DIRTY = ConcurrentHashMap.newKeySet();
    private static volatile SwoftStorage storage;
    private static volatile boolean running;
    private static Thread flushThread;

    private SeenPlayersStore() {
    }

    /**
     * Attach the configured backend, load every stored row, and start the
     * write-behind flush loop. A null config means the default files
     * backend. Any previously attached backend is flushed and closed.
     */
    public static synchronized void initialize(StorageConfigModel config) {
        shutdownActive();
        StorageConfigModel effective = config != null ? config : StorageConfigModel.defaults();
        SwoftStorage backend;
        try {
            backend = PersistStore.createBackend(effective.backend());
        } catch (Exception e) {
            System.err.println("Warning: seen-players store cannot open backend '"
                    + effective.backend().kind() + "': " + e.getMessage()
                    + " - offline players run in-memory only");
            return;
        }
        ENTRIES.clear();
        DIRTY.clear();
        try {
            for (Map.Entry<String, JsonElement> row : backend.loadAll(RESERVED_VAR).entrySet()) {
                Entry entry = parseRow(row.getValue());
                if (entry != null) {
                    ENTRIES.put(row.getKey(), entry);
                } else {
                    System.err.println("Warning: bad seen-players row for '"
                            + row.getKey() + "': " + row.getValue() + " - skipping");
                }
            }
        } catch (Exception e) {
            System.err.println("Warning: cannot load seen players: " + e.getMessage()
                    + " - starting empty");
        }
        storage = backend;
        running = true;
        long flushMillis = Math.max(1, effective.flushTicks()) * 50L;
        flushThread = Thread.ofVirtual().name("swoft-seen-players-flush").start(() -> {
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
        System.out.println("SeenPlayersStore: " + ENTRIES.size()
                + " known player(s) on backend '" + effective.backend().kind() + "'");
    }

    /** Flush and close the attached backend, if any; entries stay usable. */
    public static synchronized void shutdownActive() {
        SwoftStorage backend = storage;
        if (backend == null) {
            return;
        }
        running = false;
        if (flushThread != null) {
            flushThread.interrupt();
            try {
                flushThread.join(2_000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            flushThread = null;
        }
        try {
            flush();
        } finally {
            storage = null;
            try {
                backend.close();
            } catch (Exception e) {
                System.err.println("Warning: closing seen-players backend failed: "
                        + e.getMessage());
            }
        }
    }

    /** Push every dirty row to the backend (no-op without one). */
    public static synchronized void flush() {
        SwoftStorage backend = storage;
        if (backend == null || DIRTY.isEmpty()) {
            return;
        }
        Map<String, JsonElement> batch = new LinkedHashMap<>();
        List<String> taken = List.copyOf(DIRTY);
        for (String uuid : taken) {
            // unmark before reading so a concurrent update re-marks
            DIRTY.remove(uuid);
            Entry entry = ENTRIES.get(uuid);
            if (entry != null) {
                batch.put(uuid, toRow(entry));
            }
        }
        if (batch.isEmpty()) {
            return;
        }
        try {
            backend.writeBatch(RESERVED_VAR, batch);
        } catch (Exception e) {
            System.err.println("Warning: seen-players flush failed: " + e.getMessage()
                    + " - retrying next cycle");
            DIRTY.addAll(taken);
        }
    }

    // ------------------------------------------------------------------
    // updates
    // ------------------------------------------------------------------

    /** Join: record/refresh the name, stamp first_seen (once) + last_seen. */
    public static void recordJoin(UUID uuid, String name) {
        String now = isoNow();
        ENTRIES.compute(uuid.toString(), (key, previous) -> new Entry(name,
                previous != null && previous.firstSeen() != null ? previous.firstSeen() : now,
                now));
        DIRTY.add(uuid.toString());
    }

    /** Quit: stamp last_seen (creating the row defensively if missing). */
    public static void recordQuit(UUID uuid, String name) {
        String now = isoNow();
        ENTRIES.compute(uuid.toString(), (key, previous) -> new Entry(
                previous != null ? previous.name() : name,
                previous != null && previous.firstSeen() != null ? previous.firstSeen() : now,
                now));
        DIRTY.add(uuid.toString());
    }

    /**
     * Seed an identity without touching timestamps (Mojang fetch): the
     * player is known by name but has not necessarily played here.
     */
    public static void seed(String uuid, String name) {
        ENTRIES.compute(uuid, (key, previous) -> new Entry(name,
                previous != null ? previous.firstSeen() : null,
                previous != null ? previous.lastSeen() : null));
        DIRTY.add(uuid);
    }

    /** Harness hook: seed a full row directly (serverless roundtrips). */
    public static void seedFull(String uuid, String name, String firstSeen, String lastSeen) {
        ENTRIES.put(uuid, new Entry(name, firstSeen, lastSeen));
        DIRTY.add(uuid);
    }

    // ------------------------------------------------------------------
    // lookups
    // ------------------------------------------------------------------

    /**
     * Case-insensitive name lookup; null when never seen. Several rows can
     * share a name (a renamed-away holder keeps its stale name until that
     * account rejoins), so the winner is deterministic: the most recently
     * seen row — latest last_seen, then latest first_seen (nulls oldest),
     * then lowest uuid as a stable tiebreak. Mojang names are globally
     * unique at any instant, so the most recent joiner is by construction
     * the current owner of the name.
     */
    public static OfflinePlayerValue byName(String name) {
        String query = name.toLowerCase(Locale.ROOT);
        Map.Entry<String, Entry> best = null;
        for (Map.Entry<String, Entry> entry : ENTRIES.entrySet()) {
            if (entry.getValue().name() != null
                    && entry.getValue().name().toLowerCase(Locale.ROOT).equals(query)
                    && (best == null || NAME_WINNER.compare(entry, best) > 0)) {
                best = entry;
            }
        }
        return best != null
                ? new OfflinePlayerValue(best.getKey(), best.getValue().name())
                : null;
    }

    /** byName winner order: latest last_seen, latest first_seen, lowest uuid. */
    private static final Comparator<Map.Entry<String, Entry>> NAME_WINNER = Comparator
            .comparing((Map.Entry<String, Entry> e) -> parseInstant(e.getValue().lastSeen()),
                    Comparator.nullsFirst(Comparator.naturalOrder()))
            .thenComparing(e -> parseInstant(e.getValue().firstSeen()),
                    Comparator.nullsFirst(Comparator.naturalOrder()))
            .thenComparing(Map.Entry::getKey, Comparator.reverseOrder());

    /** Lenient ISO parse; null (sorted oldest) for missing/bad timestamps. */
    private static Instant parseInstant(String iso) {
        if (iso == null) {
            return null;
        }
        try {
            return Instant.parse(iso);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Total uuid lookup: always constructs an identity; the name comes
     * from the store when known, else "unknown". Parseable uuids are
     * normalized (lowercase canonical form) so they key persistents
     * identically to Player.getUuid().toString().
     */
    public static OfflinePlayerValue byUuid(String uuid) {
        String normalized;
        try {
            normalized = UUID.fromString(uuid.trim()).toString();
        } catch (IllegalArgumentException e) {
            normalized = uuid;
        }
        Entry entry = ENTRIES.get(normalized);
        return new OfflinePlayerValue(normalized,
                entry != null && entry.name() != null ? entry.name() : "unknown");
    }

    /** The stored row for a uuid, or null. */
    public static Entry entry(String uuid) {
        return ENTRIES.get(uuid);
    }

    /** ISO first_seen or null (pre-tracking). */
    public static String firstSeen(String uuid) {
        Entry entry = ENTRIES.get(uuid);
        return entry != null ? entry.firstSeen() : null;
    }

    /** ISO last_seen or null (pre-tracking). */
    public static String lastSeen(String uuid) {
        Entry entry = ENTRIES.get(uuid);
        return entry != null ? entry.lastSeen() : null;
    }

    /** Actually played here (join/quit tracked), not just fetched by name. */
    public static boolean hasPlayedBefore(String uuid) {
        Entry entry = ENTRIES.get(uuid);
        return entry != null && (entry.firstSeen() != null || entry.lastSeen() != null);
    }

    /** all_seen_players(): every known identity, name-sorted. */
    public static List<OfflinePlayerValue> all() {
        List<OfflinePlayerValue> players = new ArrayList<>(ENTRIES.size());
        for (Map.Entry<String, Entry> entry : ENTRIES.entrySet()) {
            players.add(new OfflinePlayerValue(entry.getKey(),
                    entry.getValue().name() != null ? entry.getValue().name() : "unknown"));
        }
        players.sort(Comparator.comparing(OfflinePlayerValue::name,
                String.CASE_INSENSITIVE_ORDER).thenComparing(OfflinePlayerValue::uuid));
        return players;
    }

    /** Known-player count (harness assertions). */
    public static int size() {
        return ENTRIES.size();
    }

    /** Drop every in-memory entry (harness isolation; backend untouched). */
    public static void clearMemory() {
        ENTRIES.clear();
        DIRTY.clear();
    }

    public static String isoNow() {
        return Instant.now().toString();
    }

    // ------------------------------------------------------------------
    // row (de)serialization
    // ------------------------------------------------------------------

    private static JsonElement toRow(Entry entry) {
        JsonObject row = new JsonObject();
        row.addProperty("name", entry.name() != null ? entry.name() : "unknown");
        if (entry.firstSeen() != null) {
            row.addProperty("first_seen", entry.firstSeen());
        }
        if (entry.lastSeen() != null) {
            row.addProperty("last_seen", entry.lastSeen());
        }
        return row;
    }

    private static Entry parseRow(JsonElement element) {
        try {
            JsonObject row = element.getAsJsonObject();
            String name = row.has("name") && !row.get("name").isJsonNull()
                    ? row.get("name").getAsString() : "unknown";
            String firstSeen = row.has("first_seen") && !row.get("first_seen").isJsonNull()
                    ? row.get("first_seen").getAsString() : null;
            String lastSeen = row.has("last_seen") && !row.get("last_seen").isJsonNull()
                    ? row.get("last_seen").getAsString() : null;
            return new Entry(name, firstSeen, lastSeen);
        } catch (Exception e) {
            return null;
        }
    }
}
