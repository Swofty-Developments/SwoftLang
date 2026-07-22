command "counts" {
    execute {
        // literal — V is inferred as Integer from the values
        set counts to { "a": 1, "b": 2, "c": 3 }

        set counts at "d" to 4               // write
        set a to counts["a"] otherwise 0     // index-read yields Optional<V>
        send "a is ${a}, size is ${size of counts}" to sender

        delete counts at "b"                 // remove one entry
        if counts has "c" {                  // membership test
            send "still counting c" to sender
        }
    }
}
