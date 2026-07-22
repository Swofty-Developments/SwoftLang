command "bad" {
    execute {
        set counts to { "a": 1 }
        map_set(counts, "b", "two")
    }
}
