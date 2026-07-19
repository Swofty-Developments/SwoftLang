persistent visits for Player: Integer = 0

event PlayerJoin {
    execute {
        set visits for event.player to visits for event.player + 1
        send "<gray>Visit #${visits for event.player}" to event.player
    }
}
