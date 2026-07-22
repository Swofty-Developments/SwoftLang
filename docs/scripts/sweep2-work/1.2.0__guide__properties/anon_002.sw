Player {
    on_chat(message) {
        set this.health to this.max_health
        set this.gamemode to "creative"
        set this.held_item.amount to 32
    }
}
