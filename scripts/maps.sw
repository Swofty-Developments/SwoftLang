// Phase-10 showcase: the Map<V> type — String-keyed dictionaries with a
// restart-safe persistent variant. Covers map literals, the natural-language
// dialect ('set m at k to v', 'm has k', 'size of m', 'keys of m', 'delete m at
// k'), the m[k] index-read sugar (Optional<V>, so it pairs with
// otherwise/exists), both foreach forms, and a persistent Map<Scalar> serialized
// as one JSON blob so it survives a restart — the player-vault pattern made
// trivial.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// A persistent map of scalars round-trips through the backend as JSON.
persistent scores: Map<Integer> = new_map()

command "inventory" {
    description: "Build an item->count map and report every entry"

    execute {
        // Map literal — V is inferred as Integer from the values.
        set counts to { "diamond": 3, "emerald": 1, "gold": 7 }

        // The 'set m at k to v' natural form writes entries.
        set counts at "iron" to 12
        set counts at "diamond" to 5      // overwrite an existing key

        send "size is ${size of counts}" to sender

        // Index read yields Optional<V>: combine with 'otherwise' for a default.
        set gold to counts["gold"] otherwise 0
        send "gold count is ${gold}" to sender

        // ...or narrow it with 'exists'.
        if counts["ruby"] exists {
            send "has ruby" to sender
        } else {
            send "no ruby" to sender
        }

        if counts has "iron" {
            send "has iron" to sender
        }

        // 'keys of m' returns a fresh insertion-ordered List<String>.
        loop keys of counts as material {
            send "key ${material}" to sender
        }

        // map foreach binds the String key and the V value per entry.
        loop counts as name -> amount {
            send "${name} x${amount}" to sender
        }

        // 'delete m at k' removes a row.
        delete counts at "emerald"
        send "after delete size is ${size of counts}" to sender
    }
}

command "record-score" {
    description: "Write into a persistent map that survives a restart"

    execute {
        // Index-set on a persistent map mutates the stored map in place; the
        // whole map is flushed to the backend as JSON.
        set scores at "team-red" to 42
        set scores at "team-blue" to 17

        set red to scores["team-red"] otherwise 0
        send "team-red has ${red}" to sender
        send "teams recorded: ${size of scores}" to sender
    }
}
