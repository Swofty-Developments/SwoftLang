struct Guild {
    name: String
    level: Integer = 1
    bank: map<String, Integer>
    home: optional<Location>
}

persistent guilds: map<String, Guild> = new_map()
