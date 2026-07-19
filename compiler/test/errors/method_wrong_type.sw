command "mw" {
    execute {
        set scores to { "a": 1 }
        set x to scores.contains(1)
        send "${x}" to sender
    }
}
