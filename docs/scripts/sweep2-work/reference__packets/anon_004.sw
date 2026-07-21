Packet {
    on "ClientInteractEntityPacket" {
        set target to packet.target_id
        async {
            // off the read thread: log, look things up, message people
            broadcast "<gray>someone poked entity ${target}"
        }
    }
}
