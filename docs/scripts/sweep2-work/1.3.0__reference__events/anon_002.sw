Mob {
    on_click {
        send "<gray>You poke a ${mob.type}." to player
    }
}

mob "ghoul" {
    type: "ZOMBIE"
    name: "<dark_green>Ghoul"
    health: 40

    on_click {
        send "<green>You poke the ghoul." to player
        call original method            // also run base Mob.on_click
    }

    on_target {
        call original method with arguments target
    }
}
