struct Guild {
    name: String
    level: Integer = 1
    members: List<Player>
    bank: Map<String, Integer>
    home: Optional<Location>
}

command "found" {
    execute {
        if sender is a Player {
            set g to Guild {
                name: "Knights",
                members: [sender],
                bank: new_map(),
                home: none
            }
            send "<green>Founded ${g.name} (level ${g.level})." to sender
        }
    }
}
