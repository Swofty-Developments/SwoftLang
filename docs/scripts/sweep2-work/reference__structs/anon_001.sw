struct Guild {
    name: String
    level: Integer = 1                 // has a default → optional at construction
    members: list<Player>
    bank: map<String, Integer>
    home: optional<Location>
}
