// Packet blocks bind `packet` to a record of the packet class's TYPED fields
// (loaded from data/packets.json). Each `packet.<field>` typechecks to the
// field's real type: message is a String, timestamp/salt/checksum Integers.
// The class name resolves either from the bare simple name or fully-qualified.
Packet {
    on "ClientChatMessagePacket" {
        // String field: concatenates into a String message
        send "<gray>chat: ${packet.message}" to player

        // Integer fields: usable in arithmetic and comparisons
        if packet.timestamp > 0 {
            broadcast "<gray>signed at ${packet.timestamp} (salt ${packet.salt}, checksum ${packet.checksum})"
        }
    }

    // fully-qualified class names resolve too; block_face is a String,
    // sequence an Integer, block_position a Location
    on "net.minestom.server.network.packet.client.play.ClientPlayerActionPacket" {
        send "<gray>action face=${packet.block_face} seq=${packet.sequence}" to player
        teleport player to packet.block_position
    }
}
