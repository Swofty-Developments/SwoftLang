command "x" {
    execute {
        set m to { "a": 1 }
        set total to m["a"] + 1
        send "${total}" to sender
    }
}
