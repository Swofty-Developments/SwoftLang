Player {
    on_join {
        send "<green>Welcome, ${player.name}!" to player
        send "<gray>${player.name} joined" to all
    }
}
