Server {
    on_tps_change(past, current) {
        if current < 15.0 {
            broadcast "<red>Server struggling: ${past} -> ${current} TPS"
        }
    }
}
