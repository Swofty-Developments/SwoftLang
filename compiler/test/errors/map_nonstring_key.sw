command "x" {
    execute {
        set m to { key: 1 }
        send "${map_size(m)}" to sender
    }
}
