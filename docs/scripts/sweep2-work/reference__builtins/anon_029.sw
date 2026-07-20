command "census" {
    execute {
        if world_exists("arena", polar_loader("worlds")) {
            send "arena is on disk" to sender
        }
        loop all_worlds(polar_loader("worlds")) as w {
            send "<gray>- ${w}" to sender
        }
    }
}
