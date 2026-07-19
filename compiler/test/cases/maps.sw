// Phase 10: the map<V> type — String-keyed dictionaries.
//
// Literal { "k": expr, ... }, the map_* builtins (map_get returns optional<V>),
// the 'set m at k to v' index-set sugar, the m[k] index-read sugar (also
// optional<V>), foreach over entries, and a restart-safe persistent map<Scalar>.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// a persistent map of scalars is serialized to the backend as JSON
persistent leaderboard: map<Integer> = new_map()

command "maps" {
    execute {
        // map literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        // builtin form and the index-set sugar both write entries
        map_set(counts, "d", 4)
        set counts at "e" to 5

        if map_has(counts, "a") {
            send "counts has a" to sender
        }

        // index read yields optional<V>: combine with 'otherwise'
        set a_count to counts["a"] otherwise 0
        send "a is ${a_count}" to sender

        // ...or narrow it with 'exists'
        if counts["z"] exists {
            send "z present" to sender
        }

        send "size is ${map_size(counts)}" to sender

        // map_keys returns list<String>, iterable with a normal foreach
        loop map_keys(counts) as key {
            send "key ${key}" to sender
        }

        // map foreach binds the String key and the V value per entry
        loop counts as name -> amount {
            send "${name} = ${amount}" to sender
        }

        map_delete(counts, "b")

        // index-set on a persistent map mutates the stored map in place
        set leaderboard at sender.name to map_size(counts)
        set best to leaderboard[sender.name] otherwise 0
        send "best ${best}" to sender
    }
}
