struct Guild {
    schema: 3

    name: String
    tag: String = ""
    balance: Double = 0.0
    motd: String = ""

    // v1 -> v2: `title` was renamed to `name`; `tag` is brand new.
    migrate to 2 {
        set name to raw["title"] otherwise "Unnamed"
        set tag to ""
    }

    // v2 -> v3: the old whole-number `coins` value flows in through `raw`
    // (typed Any) and lands in the Double `balance`; seed `motd` from `name`.
    migrate to 3 {
        set balance to raw["coins"] otherwise 0.0
        set motd to "Welcome to ${name}"
    }
}

persistent guilds: Map<String, Guild> = new_map()
