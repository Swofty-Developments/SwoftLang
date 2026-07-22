command "ambience" {
    execute {
        // radius is evaluated once at start — it does not follow players
        play song "cave_theme.nbs" at location(100.5, 40.0, 20.5) radius 16.0
    }
}

command "nightclub" {
    execute {
        play song "drop.nbs" to all
        set song volume of all players to 1.0
    }
}

command "wind-down" {
    execute {
        fade song of sender to 0.0 over 5 seconds
    }
}
