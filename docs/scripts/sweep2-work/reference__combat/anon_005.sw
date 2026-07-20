command "effects" {
    execute {
        apply "strength" 0 to sender for 200
        loop sender.active_effects as e {
            send "active: ${e}" to sender
        }
        remove "strength" from sender
    }
}
