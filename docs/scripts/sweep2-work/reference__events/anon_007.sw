event PlayerGameModeChange {
    execute {
        send "${event.player.name} -> ${event.new_game_mode}" to event.player
    }
}
