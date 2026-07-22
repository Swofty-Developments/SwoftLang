Player {
    on_chat(message) {
        set spot to this.location
        set spot.y to 300.0
        send "spot.y = ${spot.y}, and you have not moved" to this
    }
}
