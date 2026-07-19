event PlayerJoin {
    execute {
        send "<green>Welcome, ${event.player.name}!" to event.player
        send "<gray>${event.player.name} joined" to all
    }
}
