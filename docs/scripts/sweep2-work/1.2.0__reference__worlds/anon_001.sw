command "arena" {
    execute {
        create world "arena" with polar_loader("worlds")
        load world "arena" with polar_loader("worlds")
        set hub to world("arena")
        if hub exists {
            set sender.world to hub
        }
    }
}
