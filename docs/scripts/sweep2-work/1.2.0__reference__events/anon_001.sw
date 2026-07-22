Player {
    on_join() {
        broadcast "<yellow>${this.name} joined the game"
    }

    on_chat(message) {
        send "<gray>You said: ${message}" to this
    }
}
