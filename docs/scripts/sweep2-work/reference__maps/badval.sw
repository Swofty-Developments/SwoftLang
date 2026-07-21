command "bad" {
    execute {
        set counts to { "a": 1 }
        set counts at "b" to "two"
    }
}
