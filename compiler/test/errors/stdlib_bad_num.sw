command "bad" {
    execute {
        set x to sqrt("hi")
        send "${x}" to sender
    }
}
