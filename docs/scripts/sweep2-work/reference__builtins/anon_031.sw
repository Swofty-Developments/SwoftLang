command "range" {
    execute {
        if sender is a Player {
            set here to sender.location
            set target to above(here, 10)
            send "gap ${distance(here, target)}" to sender
            set push to direction_from(here, target)
            send "dir ${push.x}, ${push.y}, ${push.z}" to sender
        }
    }
}
