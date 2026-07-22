struct Guild {
    schema: 2

    name: String
    tag: String = ""

    migrate to 2 {
        set name to raw["title"] otherwise "Unnamed"
        set tag to ""
    }
}

persistent guilds: Map<String, Guild> = new_map()
