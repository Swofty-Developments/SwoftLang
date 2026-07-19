command "snippetwrap" {
    execute {
        set found to offline_player("Notch")
        if found exists {
            send "<gold>${found.name}</gold> — last seen ${found.last_seen}" to sender
            if found.player exists {
                send "<green>Someone looked you up!" to found.player
            }
        }
    }
}
