package net.swofty.items;

import net.kyori.adventure.text.format.NamedTextColor;
import net.minestom.server.item.component.ItemRarity;
import net.swofty.ScriptError;

/**
 * The four vanilla item rarities (phase 9). rarity: on an item declaration
 * maps straight onto the vanilla RARITY item component
 * ({@link ItemRarity}); the client colors the item's name accordingly.
 * SwoftLang no longer ships the Hypixel 8-value ladder or any auto lore
 * banner — appearance is exactly what the declaration asks for.
 */
public enum Rarity {
    COMMON(ItemRarity.COMMON, NamedTextColor.WHITE),
    UNCOMMON(ItemRarity.UNCOMMON, NamedTextColor.YELLOW),
    RARE(ItemRarity.RARE, NamedTextColor.AQUA),
    EPIC(ItemRarity.EPIC, NamedTextColor.LIGHT_PURPLE);

    private final ItemRarity component;
    private final NamedTextColor nameColor;

    Rarity(ItemRarity component, NamedTextColor nameColor) {
        this.component = component;
        this.nameColor = nameColor;
    }

    /** The vanilla RARITY component value this rarity applies. */
    public ItemRarity component() {
        return component;
    }

    /** The vanilla client-side name color for this rarity (fallback path). */
    public NamedTextColor nameColor() {
        return nameColor;
    }

    public static Rarity parse(String value) {
        try {
            return valueOf(value.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ScriptError("unknown rarity '" + value
                    + "' (valid: common, uncommon, rare, epic)");
        }
    }
}
