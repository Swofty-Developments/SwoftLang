function add(a: Integer, b: Integer) {
    return a + b
}

command "arity" {
    execute {
        set r to add(1)
    }
}
