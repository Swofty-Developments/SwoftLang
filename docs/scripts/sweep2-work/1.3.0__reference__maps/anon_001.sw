command "counts" {
    execute {
        // literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        map_set(counts, "d", 4)          // builtin write
        set counts at "e" to 5           // index-set sugar for the same thing

        set a to counts["a"] otherwise 0 // index-read yields optional<V>
        send "a is ${a}, size is ${map_size(counts)}" to sender

        map_delete(counts, "b")
    }
}
