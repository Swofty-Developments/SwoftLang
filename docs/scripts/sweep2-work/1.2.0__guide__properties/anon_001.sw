Player {
    on_chat(message) {
        send "you are ${this.name} at y=${this.location.y}" to this
        send "holding ${this.held_item.material}" to this
    }
}
