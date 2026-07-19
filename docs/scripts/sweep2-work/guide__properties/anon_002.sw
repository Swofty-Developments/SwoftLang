event PlayerChat {
    execute {
        set event.player.health to event.player.max_health
        set event.player.gamemode to "creative"
        set event.player.held_item.amount to 32
    }
}
