Packet {
    on "ClientPlayerActionPacket" {
        if packet.status is "START_DIGGING" {
            send "<red>No mining in the lobby." to player
            cancel packet
        }
    }
}
