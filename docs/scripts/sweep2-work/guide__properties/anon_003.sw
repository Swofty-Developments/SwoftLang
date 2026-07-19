command "vitals" {
    execute {
        if sender is a Player {
            send "you are at y=${sender.location.y}"
            set sender.gamemode to "creative"
            set sender.health to sender.max_health
            set sender.level to 10
        }
    }
}
