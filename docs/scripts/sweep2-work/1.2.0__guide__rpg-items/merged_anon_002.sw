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

command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
        send "<green>Kit delivered — right-click to Transmit." to sender
    }
}

command "kit-setup" {
    execute {
        // right-click the Aspect: a 3-second cooldown, then the effect
        on_item_use("aspect_of_the_end", "right", with_cooldown(3.0,
            function(user: Player, held: Item) {
                set dmg to held.tags.damage otherwise 0
                send "<aqua>Instant Transmission! (${dmg} dmg ready)" to user
            }))
        send "<gray>Aspect ability registered." to sender
    }
}
