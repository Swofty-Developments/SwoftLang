command "here" {
    execute {
        if sender is a Player {
            set spot to location_of(sender)
            send "you are at ${spot.x}, ${spot.y}, ${spot.z}" to sender
        }
    }
}
