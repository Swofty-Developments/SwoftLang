import "abilities"

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true

    // Your stat system — arbitrary data, yours to design.
    tags: {
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

command "inspect-sword" {
    execute {
        set sword to custom_item("aspect_of_the_end")

        // tag reads are optional<Any> — give each a fallback
        set dmg to sword.tags.damage otherwise 0
        set str to sword.tags.strength otherwise 0
        set tier to sword.tags.tier otherwise "COMMON"

        // one source of truth: the same numbers the lore displays
        set effective to dmg + str / 2
        send "<gray>${tier} sword — effective damage ${effective}" to sender
    }
}
