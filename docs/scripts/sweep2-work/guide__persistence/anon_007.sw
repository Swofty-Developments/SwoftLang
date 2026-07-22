struct Guild {
    name: String
    level: Integer = 1
    bank: Map<String, Integer>
    home: Optional<Location>
}

persistent guilds: Map<String, Guild> = new_map()
