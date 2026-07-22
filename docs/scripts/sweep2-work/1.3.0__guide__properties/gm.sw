command "gm" {
    execute {
        if sender is a Player {
            set sender.gamemode to "hardcore"
        }
    }
}
