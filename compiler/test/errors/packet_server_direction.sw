// a Packet block can only listen to INBOUND client packets. ActionBarPacket is
// an outbound server packet (net.minestom...packet.server.**), so listening to
// it can never fire — the runtime PacketSender.resolveClient rejects it too.
Packet {
    on "ActionBarPacket" {
        send "<red>bar" to player
    }
}
