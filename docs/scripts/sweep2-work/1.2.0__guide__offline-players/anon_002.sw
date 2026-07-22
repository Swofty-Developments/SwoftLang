command "snippetwrap" {
    execute {
        set found to offline_player("Notch")
        if found exists {
            if found.player exists {
                // inside this guard, found.player is a real Player
                send "<green>Someone just looked you up!" to found.player
            }
        }
    }
}
