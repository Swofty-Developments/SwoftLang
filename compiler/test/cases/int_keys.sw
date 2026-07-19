// Phase 11: Integer map keys. map<Integer, V> alongside map<String, V>, with
// key-type-aware builtins, index sugar, foreach, and a persistent Integer map.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// a persistent Integer-keyed map of scalars survives restarts
persistent scores: map<Integer, String> = new_map()

command "intkeys" {
    execute {
        // literal with integer keys infers map<Integer, String>
        set names to { 1: "one", 2: "two", 3: "three" }

        // integer-key builtin and index-set sugar both write entries
        map_set(names, 4, "four")
        set names at 5 to "five"

        if map_has(names, 1) {
            send "has 1" to sender
        }

        // index read yields optional<V>: combine with 'otherwise'
        set first to names[1] otherwise "none"
        send "first ${first}" to sender

        send "size ${map_size(names)}" to sender

        // map_keys returns list<Integer> for an Integer-keyed map
        loop map_keys(names) as k {
            send "key ${k}" to sender
        }

        // map foreach binds the Integer key and the String value per entry
        loop names as num -> word {
            send "${num} = ${word}" to sender
        }

        map_delete(names, 2)

        // persistent Integer-keyed map: index-set mutates the stored map
        set scores at 100 to "hundred"
        set best to scores[100] otherwise "none"
        send "best ${best}" to sender
    }
}
