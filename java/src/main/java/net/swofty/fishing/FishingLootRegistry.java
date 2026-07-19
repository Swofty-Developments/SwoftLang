package net.swofty.fishing;

import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.random.RandomGenerator;

import net.swofty.model.FishingLootEntryModel;
import net.swofty.model.FishingLootModel;

/**
 * Declared fishing_loot tables plus the built-in vanilla default
 * (phase 8). Matching is medium first, then world: a table whose world
 * equals the hook's world wins over a generic (world-less) table of the
 * same medium; when nothing matches at all, the vanilla default applies.
 */
public final class FishingLootRegistry {
    /** Built-in vanilla water loot: fish plus classic junk. */
    public static final FishingLootModel DEFAULT_VANILLA = new FishingLootModel(
            "__vanilla", "water", null, List.of(
                    new FishingLootEntryModel("item", "COD", 50, null),
                    new FishingLootEntryModel("item", "SALMON", 25, null),
                    new FishingLootEntryModel("item", "PUFFERFISH", 10, null),
                    new FishingLootEntryModel("item", "LILY_PAD", 5, null),
                    new FishingLootEntryModel("item", "STICK", 4, null),
                    new FishingLootEntryModel("item", "BONE", 3, null),
                    new FishingLootEntryModel("item", "STRING", 2, null),
                    new FishingLootEntryModel("item", "LEATHER_BOOTS", 1, null)),
            -1, -1);

    private static final List<FishingLootModel> TABLES = new CopyOnWriteArrayList<>();

    private FishingLootRegistry() {
    }

    public static void clear() {
        TABLES.clear();
    }

    /** Register one declared table; invalid tables warn and are skipped. */
    public static void register(FishingLootModel table) {
        if (FishingMedium.fromId(table.medium()) == null) {
            System.err.println("Error: fishing_loot '" + table.name()
                    + "': unknown medium '" + table.medium() + "' (valid: water, lava)");
            return;
        }
        if (table.entries() == null || table.entries().isEmpty()) {
            System.err.println("Error: fishing_loot '" + table.name()
                    + "' has no catch entries - skipping");
            return;
        }
        for (FishingLootEntryModel entry : table.entries()) {
            if (!entry.kind().equals("item") && !entry.kind().equals("mob")) {
                System.err.println("Error: fishing_loot '" + table.name()
                        + "': unknown catch kind '" + entry.kind()
                        + "' (valid: item, mob) - skipping table");
                return;
            }
            if (!(entry.weight() > 0)) {
                System.err.println("Error: fishing_loot '" + table.name() + "': catch '"
                        + entry.id() + "' needs a positive weight, got " + entry.weight()
                        + " - skipping table");
                return;
            }
        }
        TABLES.add(table);
    }

    /** All registered tables (harness introspection). */
    public static List<FishingLootModel> all() {
        return List.copyOf(TABLES);
    }

    /**
     * Best table for a hook: world-specific beats generic within the
     * medium; no match falls back to the built-in vanilla table.
     */
    public static FishingLootModel match(FishingMedium medium, String world) {
        FishingLootModel generic = null;
        for (FishingLootModel table : TABLES) {
            if (!table.medium().equalsIgnoreCase(medium.id())) {
                continue;
            }
            if (table.world() != null) {
                if (world != null && table.world().equals(world)) {
                    return table;
                }
            } else if (generic == null) {
                generic = table;
            }
        }
        return generic != null ? generic : DEFAULT_VANILLA;
    }

    /** Weighted roll over a table's entries; null only for empty lists. */
    public static FishingLootEntryModel roll(List<FishingLootEntryModel> entries,
            RandomGenerator random) {
        double total = 0;
        for (FishingLootEntryModel entry : entries) {
            total += entry.weight();
        }
        if (total <= 0) {
            return null;
        }
        double pick = random.nextDouble() * total;
        for (FishingLootEntryModel entry : entries) {
            pick -= entry.weight();
            if (pick < 0) {
                return entry;
            }
        }
        return entries.get(entries.size() - 1);
    }
}
