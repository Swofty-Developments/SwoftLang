command "bad" {
    execute {
        set x to parse("42", Whatever) otherwise 0
        send "${x}" to sender
    }
}
