hologram "welcome" {
    location: location(0.5, 82.0, 0.5)
    lines {
        line "<gold><bold>SwoftLang"
        line "<gray>have a look around"
    }
}

event PlayerJoin {
    execute {
        if event.first_spawn {
            show hologram "welcome" to event.player
        }
    }
}
