command "a", command "b", "c" {
    execute {
        halt
    }
}

command "d", {
    description: "trailing comma, no execute"
}
