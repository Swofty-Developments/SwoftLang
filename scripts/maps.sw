// Phase-10 showcase: the map<V> type — String-keyed dictionaries with a
// restart-safe persistent variant. Covers map literals, the map_* builtins
// (map_get returns optional<V>), the 'set m at k to v' index-set sugar, the
// m[k] index-read sugar (also optional<V>, so it pairs with otherwise/exists),
// both foreach forms, and a persistent map<Scalar> serialized as one JSON blob
// so it survives a restart — the player-vault pattern made trivial.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// A persistent map of scalars round-trips through the backend as JSON.
persistent scores: map<Integer> = new_map()

command "inventory" {
    description: "Build an item->count map and report every entry"

    execute {
        // Map literal — V is inferred as Integer from the values.
        set counts to { "diamond": 3, "emerald": 1, "gold": 7 }

        // The builtin and the 'set m at k to v' sugar both write entries.
        map_set(counts, "iron", 12)
        set counts at "diamond" to 5      // overwrite an existing key

        send "size is ${map_size(counts)}" to sender

        // Index read yields optional<V>: combine with 'otherwise' for a default.
        set gold to counts["gold"] otherwise 0
        send "gold count is ${gold}" to sender

        // ...or narrow it with 'exists'.
        if counts["ruby"] exists {
            send "has ruby" to sender
        } else {
            send "no ruby" to sender
        }

        if map_has(counts, "iron") {
            send "has iron" to sender
        }

        // map_keys returns a fresh insertion-ordered list<String>.
        loop map_keys(counts) as material {
            send "key ${material}" to sender
        }

        // map foreach binds the String key and the V value per entry.
        loop counts as name -> amount {
            send "${name} x${amount}" to sender
        }

        // Storing none (or map_delete) removes a row.
        map_delete(counts, "emerald")
        send "after delete size is ${map_size(counts)}" to sender
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
        send "teams recorded: ${map_size(scores)}" to sender
    }
}
