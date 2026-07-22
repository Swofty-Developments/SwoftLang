command "snippetwrap" {
    execute {
        set found to offline_player("Notch")
        if found exists {
            send "<gold>${found.name}</gold> — last seen ${found.last_seen}" to sender
        } else {
            send "never seen anyone by that name" to sender
        }
    }
}
