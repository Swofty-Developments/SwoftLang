command "x" {
    execute {
        set m to { "a": 1, "b": 2 }
        set present to m.has(5)
        if present {
            send "yes" to sender
        }
    }
}
