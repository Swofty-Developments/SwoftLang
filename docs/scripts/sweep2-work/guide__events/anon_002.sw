Player {
    on_join() {
        broadcast "<yellow>${this.name} joined the game"
        send "<green>Welcome, ${this.name}!" to this
    }
}
