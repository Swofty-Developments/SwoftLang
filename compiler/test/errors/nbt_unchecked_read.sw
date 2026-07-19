item "gem" {
    material: "EMERALD"
}

event PlayerUseItem {
    execute {
        set event.player.level to event.item.tags.power
    }
}
