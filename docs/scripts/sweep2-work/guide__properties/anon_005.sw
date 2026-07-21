Player {
    on_chat {
        set spot to player.location
        set spot.y to 300.0
        send "spot.y = ${spot.y}, and you have not moved" to player
    }
}
