item AspectOfTheEnd {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true

    tags: {
        damage: 100,
        meta: { tier: 3, keywords: ["end", "sword"] }
    }

    lore {
        line "<gray>A legendary blade from the End."
        blank
        line "<dark_gray>Soulbound"
    }
}

command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
        send "<green>Kit delivered." to sender
    }
}
