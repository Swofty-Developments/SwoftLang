event PlayerJoin {
    execute {
        send "hi ${event.player.nmae}" to event.player
    }
}
