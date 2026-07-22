persistent kills for Player: Integer = 0

command "addkill" {
    execute {
        if sender is a Player {
            set kills for sender to (kills for sender) + 1
            send "<gray>Lifetime kills: ${kills for sender}" to sender
        }
    }
}
