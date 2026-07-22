command "dispense-demo" {
    execute {
        dispense from location(0.0, 64.0, 0.0)
        send "<gray>Fired the dispenser at 0, 64, 0." to sender
    }
}
