persistent home for Player: Location = location(0, 64, 0)

command "home" {
    execute {
        teleport sender to home for sender
    }
}
