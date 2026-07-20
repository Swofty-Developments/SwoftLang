command "warp" {
    execute {
        set hub to world("hub")
        if hub exists {
            set sender.world to hub
        } else {
            send "<red>hub world is not registered" to sender
        }
    }
}
