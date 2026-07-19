command "midnight" {
    execute {
        set sender.world.time to 18000
        set sender.world.time_rate to 0      // stay midnight
    }
}
