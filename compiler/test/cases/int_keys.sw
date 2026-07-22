// Phase 11: Integer map keys. Map<Integer, V> alongside Map<String, V>, with
// key-type-aware builtins, index sugar, foreach, and a persistent Integer map.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

// a persistent Integer-keyed map of scalars survives restarts
persistent scores: Map<Integer, String> = new_map()

command "intkeys" {
    execute {
        // literal with integer keys infers Map<Integer, String>
        set names to { 1: "one", 2: "two", 3: "three" }

        // the 'set m at k to v' natural form writes integer-keyed entries
        set names at 4 to "four"
        set names at 5 to "five"

        if names has 1 {
            send "has 1" to sender
        }

        // index read yields Optional<V>: combine with 'otherwise'
        set first to names[1] otherwise "none"
        send "first ${first}" to sender

        send "size ${size of names}" to sender

        // 'keys of m' yields List<Integer> for an Integer-keyed map
        loop keys of names as k {
            send "key ${k}" to sender
        }

        // map foreach binds the Integer key and the String value per entry
        loop names as num -> word {
            send "${num} = ${word}" to sender
        }

        delete names at 2

        // persistent Integer-keyed map: index-set mutates the stored map
        set scores at 100 to "hundred"
        set best to scores[100] otherwise "none"
        send "best ${best}" to sender
    }
}
