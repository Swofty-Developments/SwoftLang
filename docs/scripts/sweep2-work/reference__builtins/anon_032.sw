command "ceiling" {
    execute {
        if sender is a Player {
            teleport sender to above(sender.location, 5)
        }
    }
}
