command "bad" {
    execute {
        set x to sum(["a", "b"])
        send "${x}" to sender
    }
}
