import "abilities"

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true

    // Your stat system — arbitrary data, yours to design.
    tags {
        damage: 100,
        strength: 80,
        crit_damage: 25,
        tier: "LEGENDARY"
    }

    // WYSIWYG lore: write exactly the tooltip you want players to see.
    lore {
        line "<gray>Damage: <red>+100"
        line "<gray>Strength: <red>+80"
        line "<gray>Crit Damage: <blue>+25%"
        blank
        line "<dark_purple><bold>LEGENDARY"
    }
}
