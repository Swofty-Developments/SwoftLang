item AspectOfTheEnd {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true
    amount: 1

    lore {
        line "<gray>A legendary blade from the End."
        blank
        line "<dark_gray>Soulbound"
    }

    tags: {
        damage: 100,
        meta: { tier: 3, keywords: ["end", "sword"] }
    }
}

command "sword" {
    execute {
        give item "aspect_of_the_end" to sender
    }
}
