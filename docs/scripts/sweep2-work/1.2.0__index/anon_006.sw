persistent visits for Player: Integer = 0

Player {
    on_join() {
        set visits for this to visits for this + 1
        send "<gray>Visit #${visits for this}" to this
    }
}
