Mob {
    on_click(player) {
        send "<gray>You poke a ${this.type}." to player
    }
}

mob "ghoul" {
    type: "ZOMBIE"
    name: "<dark_green>Ghoul"
    health: 40

    on_click(player) {
        send "<green>You poke the ghoul." to player
        default()                       // also run base Mob.on_click
    }

    on_target(target) {
        super.on_target(target)
    }
}
