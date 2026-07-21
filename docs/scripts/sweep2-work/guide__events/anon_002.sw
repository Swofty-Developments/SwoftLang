Player {
    on_join {
        broadcast "<yellow>${player.name} joined the game"
        send "<green>Welcome, ${player.name}!" to player
    }
}
