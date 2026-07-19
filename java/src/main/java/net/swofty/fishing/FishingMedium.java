package net.swofty.fishing;

import net.minestom.server.instance.block.Block;

/**
 * What the bobber can settle in (phase 8, modeled on the SkyBlock
 * fishing stack): water or lava, detected from the liquid block at the
 * bobber. Loot tables declare their medium with the same names.
 */
public enum FishingMedium {
    WATER,
    LAVA;

    /** Does this liquid block belong to the medium? */
    public boolean matches(Block block) {
        if (block == null || !block.isLiquid()) {
            return false;
        }
        String name = block.name();
        return switch (this) {
            case WATER -> name.contains("water");
            case LAVA -> name.contains("lava");
        };
    }

    /** The medium of a block, or null when it is not a fishable liquid. */
    public static FishingMedium fromBlock(Block block) {
        for (FishingMedium medium : values()) {
            if (medium.matches(block)) {
                return medium;
            }
        }
        return null;
    }

    /** Loot-table spelling ("water"/"lava"). */
    public String id() {
        return name().toLowerCase();
    }

    public static FishingMedium fromId(String id) {
        for (FishingMedium medium : values()) {
            if (medium.id().equalsIgnoreCase(id)) {
                return medium;
            }
        }
        return null;
    }
}
