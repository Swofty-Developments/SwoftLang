// v1.5.0 phase 3: in-place field / index mutation of a persistent-rooted
// struct or collection. A '.field' / '[k]' / 'at k' tail on a persistent place
// mutates the live store value in place and re-stores it so the periodic flush
// marks the row dirty and re-serializes the whole blob (durable).
storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

struct Point {
    x: Integer
    y: Integer = 0
}

struct Guild {
    name: String
    level: Integer = 1
    bank: Map<String, Integer>
    hq: Point
}

struct Duel {
    arena: Location
    score: Map<String, Integer>
}

persistent gstate: Guild = Guild { name: "server", bank: new_map(), hq: Point { x: 0 } }
persistent guild for Player: Guild = Guild { name: "", bank: new_map(), hq: Point { x: 0 } }
persistent duel for Player: Duel = Duel { arena: location(0, 64, 0), score: new_map() }

command "guildmut" {
    execute {
        // keyed persistent struct: scalar field, in place
        set (guild for sender).level to 5
        // keyed persistent struct: nested struct field, in place
        set (guild for sender).hq.x to 10
        // keyed persistent struct: map field index-set ('at' form)
        set (guild for sender).bank at "gold" to 100
        // keyed persistent struct: map field index-set ('[]' form)
        set (guild for sender).bank["silver"] to 50

        // global persistent struct: bare field path
        set gstate.level to 7
        set gstate.bank at "gold" to 1

        // nested duel: score map index-set through the keyed struct place
        set (duel for sender).score at "round1" to 3

        // whole-name reassignment still works (unchanged emit)
        set guild for sender to (guild for sender)
    }
}
