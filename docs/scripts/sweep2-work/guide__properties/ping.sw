event PlayerChat {
    execute {
        send "ping: ${event.player.latencey}ms" to event.player
    }
}
