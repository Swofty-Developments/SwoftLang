function double(n: Integer) {
    return n * 2
}

command "demo" {
    execute {
        send "${double(2, 3)}" to sender
    }
}
