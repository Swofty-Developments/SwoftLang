event PlayerChat {
    execute {
        set spot to event.player.location
        set spot.y to 300.0
        send "spot.y = ${spot.y}, and you have not moved" to event.player
    }
}
