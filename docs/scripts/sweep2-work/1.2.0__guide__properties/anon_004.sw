command "wall" {
    execute {
        if sender is a Player {
            set sender.location.x to 100.5
        }
    }
}
