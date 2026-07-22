persistent visits for Player: Integer = 0

Player {
    on_join {
        set visits for player to visits for player + 1
        send "<gray>Visit #${visits for player}" to player
    }
}
