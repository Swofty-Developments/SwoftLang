command "x" {
    execute {
        set m to { "a": 1 }
        if m has 5 {
            send "y" to sender
        }
    }
}
