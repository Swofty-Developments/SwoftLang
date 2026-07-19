event PlayerChat {
    execute {
        send "you are ${event.player.name} at y=${event.player.location.y}" to event.player
        send "holding ${event.player.held_item.material}" to event.player
    }
}
