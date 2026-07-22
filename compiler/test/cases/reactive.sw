// §4 reactive struct fields: an @EventReceiver field is an event subject; the
// matching reactive block declares param-less instance handlers whose vocabulary
// is the FIELD TYPE's (a: Player -> Player handlers). Inside a handler the
// struct's OTHER fields + the subject field + the event's vars are all in scope
// as bare names (no `this`). A struct carrying @EventReceiver fields must be
// serializable (reactive => persistent-capable); its liveness is persistence-
// rooted (§4.2), so a Duel lives the instant it enters a persistent container.
storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

struct Duel {
    @EventReceiver a: Player
    @EventReceiver b: Player
    arena: Location
    score: Map<Player, Integer>

    a {
        on_death {
            // full struct context bound as bare vars: a, b, arena, score
            set score at b to (score[b] otherwise 0) + 1
            teleport a to arena
            broadcast "<yellow>${b.name} leads the duel"
        }
    }
    b {
        on_death {
            set score at a to (score[a] otherwise 0) + 1
            teleport b to arena
            broadcast "<yellow>${a.name} leads the duel"
        }
    }
}

persistent duels: Map<String, Duel> = new_map()

command "duel" {
    execute {
        set d to Duel { a: sender, b: sender, arena: location_of(sender), score: new_map() }
        // live the instant it is reachable from the persistent root
        set duels at "arena1" to d
    }
}

command "endduel" {
    execute {
        // §4.2 teardown: removing the instance from the persistent root re-stores
        // the map (durable) and rebuilds the liveness index, so a/b stop reacting.
        delete duels at "arena1"
    }
}
