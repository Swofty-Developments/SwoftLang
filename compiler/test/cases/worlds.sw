// phase-6 worlds: loader builtins, world lifecycle statements, queries

command "arena" {
    arguments {
        name: String
    }
    execute async {
        set loader to polar_loader("worlds/")
        if world_exists(args.name, loader) {
            load world args.name with loader
            send "<green>Loaded ${args.name}" to sender
        } else {
            create world args.name with loader
            send "<yellow>Created ${args.name}" to sender
        }
        loop all_worlds(loader) as w
            send "world: ${w}" to sender
    }
}

command "arenaadmin" {
    execute async {
        create world "template" readonly with anvil_loader("template-world/")
        clone world "template" to "arena-live" with polar_loader("worlds/")
        save world "arena-live"
        unload world "arena-live" without saving teleporting players to location(0, 100, 0)
        delete world "arena-live" with polar_loader("worlds/")
        unload world "template"
        import anvil world "vanilla-world/" as "lobby" with polar_storage_loader(sqlite "worlds.db")
        import anvil world "hub-src/" as "hub" with polar_storage_loader(files "world-store")
    }
}
