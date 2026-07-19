on packet "ClientInteractEntityPacket" {
    execute {
        set target to packet.targetId
        async {
            // off the read thread: log, look things up, message people
            broadcast "<gray>someone poked entity ${target}"
        }
    }
}
