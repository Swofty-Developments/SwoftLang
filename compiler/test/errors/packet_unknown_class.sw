// an `on "..."` class name that is not in the packet catalog is rejected, with
// a nearest-match suggestion (ClientPlayerActionPacket is the real digging packet)
Packet {
    on "ClientPlayerActionPackt" {
        send "<red>dig" to player
    }
}
