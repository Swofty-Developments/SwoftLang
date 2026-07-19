command "x" {
    execute {
        set m to { 1: "one", 2: "two" }
        set v to m["nope"] otherwise "missing"
        send "${v}" to sender
    }
}
