scoreboard "main" {
    title: "<yellow><bold>SWOFTLANG"
    update: every 4 ticks
    numbers: hidden

    lines {
        line "<gray>${player.name}"
        blank
        line " <white>Health: <red>${player.health}"
        if player.level > 0 {
            line " <white>Level: <aqua>${player.level}"
        } else {
            line " <white>Level: <gray>none yet"
        }
        blank
        line "<yellow>www.swofty.net"
    }
}

command "sb" {
    execute {
        show scoreboard "main" to sender      // create lazily + add viewer
        update scoreboard for sender          // force one refresh now
        hide scoreboard from sender           // remove whatever board they see
    }
}
