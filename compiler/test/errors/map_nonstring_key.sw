command "x" {
    execute {
        set m to { key: 1 }
        send "${size of m}" to sender
    }
}
