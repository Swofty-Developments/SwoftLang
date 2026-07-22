// Phase 10: the Map<V> type — String-keyed dictionaries.
//
// Literal { "k": expr, ... }, the natural-language map dialect ('set m at k to
// v', 'm has k', 'size of m', 'keys of m', 'delete m at k'), the m[k] index-read
// sugar (Optional<V>), foreach over entries, and a restart-safe persistent
// Map<Scalar>.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// a persistent map of scalars is serialized to the backend as JSON
persistent leaderboard: Map<Integer> = new_map()

command "maps" {
    execute {
        // map literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        // the 'set m at k to v' natural form writes entries
        set counts at "d" to 4
        set counts at "e" to 5

        if counts has "a" {
            send "counts has a" to sender
        }

        // index read yields Optional<V>: combine with 'otherwise'
        set a_count to counts["a"] otherwise 0
        send "a is ${a_count}" to sender

        // ...or narrow it with 'exists'
        if counts["z"] exists {
            send "z present" to sender
        }

        send "size is ${size of counts}" to sender

        // 'keys of m' yields List<String>, iterable with a normal foreach
        loop keys of counts as key {
            send "key ${key}" to sender
        }

        // map foreach binds the String key and the V value per entry
        loop counts as name -> amount {
            send "${name} = ${amount}" to sender
        }

        delete counts at "b"

        // index-set on a persistent map mutates the stored map in place
        set leaderboard at sender.name to size of counts
        set best to leaderboard[sender.name] otherwise 0
        send "best ${best}" to sender
    }
}
