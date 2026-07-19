package net.swofty.model;

/**
 * One drops{} row of a mob declaration: a custom item id (or vanilla
 * material fallback), a 0..1 chance, and an amount.
 */
public record MobDropModel(String itemId, double chance, int amount) {
}
