Server {
    on_tps_change {
        if current < 15.0 {
            broadcast "<red>Server struggling: ${past} -> ${current} TPS"
        }
    }
}
