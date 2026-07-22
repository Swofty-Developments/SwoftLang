struct Guild {
    name: String
    level: Integer = 1
    members: List<Player>
    bank: Map<String, Integer>
    home: Optional<Location>
}

storage {
    backend: sqlite "data/guilds.db"
    flush: every 10 seconds
}

persistent guilds: Map<String, Guild> = new_map()

command "found" {
    execute {
        if sender is a Player {
            set guilds at "knights" to Guild {
                name: "Knights",
                members: [sender],
                bank: new_map(),
                home: sender.location
            }
            send "<green>Guild saved — survives a restart." to sender
        }
    }
}
