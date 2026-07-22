struct Guild {
    name: String
    level: Integer = 1
    members: list<Player>
}

command "found" {
    execute {
        set g to Guild { level: 3 }
    }
}
