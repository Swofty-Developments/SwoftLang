package net.swofty.model;

import java.util.List;

/**
 * fishing_loot "name" { medium, [world], catch... } declaration
 * (phase 8). Tables are matched by medium plus optional world name
 * (world-specific tables win over generic ones); when nothing matches,
 * the built-in vanilla table applies.
 */
public record FishingLootModel(
        String name,
        String medium,
        String world,
        List<FishingLootEntryModel> entries,
        int line,
        int col) {
}
