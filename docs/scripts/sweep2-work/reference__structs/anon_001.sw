struct Guild {
    name: String
    level: Integer = 1                 // has a default → optional at construction
    members: List<Player>
    bank: Map<String, Integer>
    home: Optional<Location>
}
