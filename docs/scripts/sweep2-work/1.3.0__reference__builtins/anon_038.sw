command "tps" {
    execute {
        send "TPS: ${tps_string()} <gray>(5m: ${average_tps_string()}<gray>)" to sender
        send "<gray>60s ago: ${tps_at(60)}" to sender
    }
}
