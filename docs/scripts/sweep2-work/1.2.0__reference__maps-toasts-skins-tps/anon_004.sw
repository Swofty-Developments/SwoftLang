command "lag" {
    execute {
        send "TPS ${tps_string()} <gray>(5m ${average_tps_string()}<gray>, ${server.mspt} mspt)" to sender
        send "<gray>one minute ago: ${tps_at(60)}" to sender
    }
}
