// Phase-9 §3 RPG pattern: lore lines interpolate the item's own tag data and
// its id. The runtime (ItemLoreBuilder.LoreCollector.initialVars) binds
// 'item_id' (String) and 'tags' (the nested tag tree) into the lore
// environment, so ${item_id}, ${tags.x}, and ${tags.meta.tier} render, and
// the lore block's if/loop can branch on that in-scope data.

item FlameBlade {
    material: "DIAMOND_SWORD"
    name: "<red>Flame Blade"
    rarity: rare
    lore {
        line "<gray>Id: ${item_id}"
        line "<red>Damage: ${tags.damage}"
        line "<gold>Tier ${tags.meta.tier}"
        blank
        if tags.soulbound {
            line "<dark_gray>Soulbound"
        }
        loop tags.meta.tier times {
            line "<yellow>*"
        }
    }
    tags: {
        damage: 120
        soulbound: true
        meta: {
            tier: 4
            origin: "the_nether"
        }
    }
}
