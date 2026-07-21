Packet {
    on "ClientPlayerActionPacket" {
        broadcast "<gray>${player.name} sent a player-action packet"
    }
}
