Player {
    on_chat {
        send "you are ${player.name} at y=${player.location.y}" to player
        send "holding ${player.held_item.material}" to player
    }
}
