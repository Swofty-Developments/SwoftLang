item "gem" {
    material: "EMERALD"
}

Item {
    on_use(player) {
        set player.level to this.tags.power
    }
}
