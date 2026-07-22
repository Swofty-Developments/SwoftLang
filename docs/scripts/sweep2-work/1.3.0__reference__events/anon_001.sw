Player {
    on_join {
        broadcast "<yellow>${player.name} joined the game"
    }

    on_chat {
        send "<gray>You said: ${message}" to player
    }
}
