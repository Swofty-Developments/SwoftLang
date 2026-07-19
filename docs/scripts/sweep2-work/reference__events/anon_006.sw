event PlayerMove {
    execute {
        if event.on_ground {
            set event.new_position to event.player.location
        }
    }
}
