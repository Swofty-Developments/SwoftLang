command "arena-setup" {
    permission: "myserver.admin"

    execute {
        set loader to anvil_loader("worlds/")

        if world_exists("arena", loader) {
            load world "arena" with loader
        } else {
            create world "arena" with loader
        }

        set w to world("arena")
        if w exists {
            set w.time to 6000
            teleport sender to location(0.5, 65.0, 0.5)
        }
    }
}

command "arena-reset" {
    permission: "myserver.admin"

    execute {
        unload world "arena" teleporting players to location(0.5, 65.0, 0.5)
        send "<green>Arena unloaded; players rescued to spawn." to sender
    }
}
