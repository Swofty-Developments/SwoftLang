hologram "spawn_info" {
    location: location(0, 65, 0)
    billboard: center
    scale: 1.5
    update: every 1 seconds
    lines {
        line "<gold><bold>Welcome!"
        blank
        line "<gray>Hi ${player.name}"
        if player.health > 10 {
            line "<green>Healthy"
        } else {
            line "<red>Careful"
        }
    }
}

command "welcome" {
    execute {
        show hologram "spawn_info" to sender
    }
}
