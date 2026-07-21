item "gem" {
    material: "EMERALD"
}

Item {
    on_use {
        set player.level to item.tags.power
    }
}
