event PlayerJoin {
    execute {
        broadcast "<yellow>${event.player.name} joined the game"
        send "<green>Welcome, ${event.player.name}!" to event.player
    }
}
