command "inzone" {
    execute {
        if sender is a Player {
            set a to location(0, 60, 0)
            set b to location(32, 90, 32)
            if is_within(sender.location, a, b) {
                send "<green>inside the arena" to sender
            } else {
                send "<red>outside" to sender
            }
        }
    }
}
