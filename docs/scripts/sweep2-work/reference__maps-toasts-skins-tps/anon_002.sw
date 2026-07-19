event PlayerJoin {
    execute {
        if event.first_spawn {
            show toast "<gold>Welcome!" description "Have a look around" icon "COMPASS" frame task to event.player
        }
    }
}
