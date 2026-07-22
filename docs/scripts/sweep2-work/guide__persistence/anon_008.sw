struct Guild {
    title: String
    coins: Integer = 0
}

persistent guilds: Map<String, Guild> = new_map()
