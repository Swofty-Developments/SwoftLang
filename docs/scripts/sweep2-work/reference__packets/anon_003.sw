on packet "ClientPlayerDiggingPacket" {
    execute {
        if packet.status is "STARTED_DIGGING" {
            send "<red>No mining in the lobby." to player
            cancel packet
        }
    }
}
