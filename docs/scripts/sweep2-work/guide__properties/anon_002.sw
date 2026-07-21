Player {
    on_chat {
        set player.health to player.max_health
        set player.gamemode to "creative"
        set player.held_item.amount to 32
    }
}
