command "counts" {
    execute {
        // literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        counts.set("d", 4)                   // write
        set a to counts.get("a") otherwise 0 // .get yields optional<V>
        send "a is ${a}, size is ${counts.size}" to sender

        counts.delete("b")                   // remove one entry
        if counts.has("c") {                 // membership test
            send "still counting c" to sender
        }
    }
}
