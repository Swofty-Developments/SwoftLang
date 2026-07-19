command "find" {
    arguments {
        name: String
    }
    execute {
        set target to player(args.name)
        if target exists {
            send "found ${target.name}, ping ${target.latency}ms" to sender
        } else {
            send "<red>nobody called ${args.name} is online" to sender
        }
    }
}
