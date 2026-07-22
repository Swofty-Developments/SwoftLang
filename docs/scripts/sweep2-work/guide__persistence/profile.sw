// v1 stored { name, title }. This is v2: `nickname` is new (old rows heal to
// "friend"), and the old `title` column is gone (dropped on load). No schema
// bump, no migrate block — reads stay total and nothing crashes.
struct Profile {
    name: String
    nickname: String = "friend"
    joins: Integer = 0
}

persistent profile for Player: Profile = Profile { name: "" }
