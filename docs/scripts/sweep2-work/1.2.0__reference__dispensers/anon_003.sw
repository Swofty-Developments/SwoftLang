Block {
    on_dispense(item, direction) {
        send "<gray>A dispenser fired, facing ${direction}." to all players
    }
}
