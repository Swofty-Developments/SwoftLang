command "x" {
    execute {
        set m to { 1: "a", "b": 2 }
        send "${size of m}" to sender
    }
}
