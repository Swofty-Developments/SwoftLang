struct Guild {
    name: String
    level: Integer = 1
}

function promote(gld: Guild) {
    set gld.level to gld.level + 1      // mutates the caller's instance
}

command "promote" {
    execute {
        set g to Guild { name: "Knights" }
        promote(g)
        set snapshot to g.copy()        // detached shallow copy
        promote(g)
        // g.level is 3; snapshot.level is frozen at 2
        send "<gray>now ${g.level}, snapshot ${snapshot.level}" to sender
    }
}
