// §5 versioned schema migration. Guild went v1 -> v2 -> v3:
//   v1: { title: String, level: Integer }
//   v2: renamed `title` -> `name`, added `tag` (backfilled "")
//   v3: added `motd` (backfilled from `tag`)
struct Guild {
    schema: 3
    name: String
    tag: String = ""
    level: Integer = 1
    motd: String = ""

    migrate to 2 {
        set name to raw["title"] otherwise ""
        set tag to ""
    }

    migrate to 3 {
        set motd to raw["tag"] otherwise ""
    }
}

// A purely additive change needs NO migrate block — Tier-1 auto-heal fills the
// new `nickname` field from its default on any stored row that predates it.
struct Profile {
    schema: 2
    name: String
    nickname: String = "friend"
}

persistent guild for Player: Guild = Guild { name: "" }
persistent profile for Player: Profile = Profile { name: "" }
