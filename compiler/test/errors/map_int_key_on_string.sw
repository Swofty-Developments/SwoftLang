command "x" {
    execute {
        set m to { "a": 1, "b": 2 }
        set has to map_has(m, 5)
        if has {
            send "yes" to sender
        }
    }
}
