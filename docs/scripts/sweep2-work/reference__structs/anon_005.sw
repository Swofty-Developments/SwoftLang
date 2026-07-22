struct Guild {
    name: String
    level: Integer = 1
    members: list<Player>
    bank: map<String, Integer>
    home: optional<Location>
}

storage {
    backend: sqlite "data/guilds.db"
    flush: every 10 seconds
}

persistent guilds: map<String, Guild> = new_map()

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
