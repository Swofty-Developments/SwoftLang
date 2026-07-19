command "bad" {
    execute {
        set add to function(a: Integer, b: Integer) return a + b
        set r to add(1)
    }
}
