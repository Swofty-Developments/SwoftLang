command "day" {
    execute {
        set w to world("lobby")
        if w exists {
            set w.time to 1000
            set w.time_rate to 1
            send "<yellow>Sunrise." to sender
        }
    }
}
