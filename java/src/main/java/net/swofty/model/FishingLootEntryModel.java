package net.swofty.model;

/**
 * One catch line of a fishing_loot table (phase 8): kind is "item"
 * (vanilla material or custom item registry id) or "mob" (custom mob
 * registry id, spawned at the hook); weight drives the weighted roll;
 * message is an optional per-entry chat line sent to the fisher.
 */
public record FishingLootEntryModel(
        String kind,
        String id,
        double weight,
        String message) {
}
