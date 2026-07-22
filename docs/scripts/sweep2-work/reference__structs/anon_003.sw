struct Guild {
    name: String
    level: Integer = 1
    bank: map<String, Integer>
    home: optional<Location>
}

command "guild-admin" {
    execute {
        if sender is a Player {
            set g to Guild { name: "Knights", bank: new_map(), home: none }
            send "<gray>${g.name} lvl ${g.level}" to sender
            set g.level to g.level + 1
            set g.bank at "gold" to 100         // map op through the field
            if g.home exists {
                teleport sender to g.home        // optional narrowed inside the guard
            }
        }
    }
}
