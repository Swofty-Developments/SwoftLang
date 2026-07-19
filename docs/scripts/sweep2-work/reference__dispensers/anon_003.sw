event BlockDispense {
    execute {
        send "<gray>A dispenser fired at ${event.location}." to all players
    }
}
