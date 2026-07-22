item RottenScimitar {
    material: "GOLDEN_SWORD"
    name: "Rotten Scimitar"
    rarity: uncommon
}

mob ArmedGhoul {
    type: "ZOMBIE"

    drops {
        item "rotten_scimitar" chance 0.05 amount 1
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }
}
