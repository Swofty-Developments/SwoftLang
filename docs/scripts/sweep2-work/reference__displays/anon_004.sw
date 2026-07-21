hologram "welcome" {
    location: location(0.5, 82.0, 0.5)
    lines {
        line "<gold><bold>SwoftLang"
        line "<gray>have a look around"
    }
}

Player {
    on_join() {
        show hologram "welcome" to this
    }
}
