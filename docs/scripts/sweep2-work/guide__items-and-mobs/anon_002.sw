item AspectOfTheEnd {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare

    lore {
        line "<gray>A legendary blade from the End."
    }
}

command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
    }
}
