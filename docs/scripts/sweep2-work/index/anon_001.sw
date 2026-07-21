Player {
    on_join() {
        send "<green>Welcome, ${this.name}!" to this
        send "<gray>${this.name} joined" to all
    }
}
