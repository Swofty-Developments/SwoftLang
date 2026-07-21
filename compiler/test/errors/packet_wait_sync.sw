Packet {
    on "ClientPlayerActionPacket" {
        wait 5 ticks
        cancel packet
    }
}
