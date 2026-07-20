command "bad" {
    execute {
        set x to strip_color(5)
        send "${x}" to sender
    }
}
