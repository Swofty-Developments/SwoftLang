event TpsChange {
    execute {
        if event.current < 15.0 {
            broadcast "<red>Server struggling: ${event.past} -> ${event.current} TPS"
        }
    }
}
