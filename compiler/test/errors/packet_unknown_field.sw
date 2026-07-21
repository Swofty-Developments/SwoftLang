// reading a field that the packet class does not have is rejected, listing a
// nearest match from the packet's real fields (message/timestamp/salt/...)
Packet {
    on "ClientChatMessagePacket" {
        send "<gray>${packet.mesage}" to player
    }
}
