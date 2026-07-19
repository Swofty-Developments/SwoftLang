command "x" {
    execute {
        set m to { 1: "a", "b": 2 }
        send "${map_size(m)}" to sender
    }
}
