command "pick" {
    execute {
        set victim to player("Alex") otherwise player("Steve") otherwise sender
        send "picked ${victim}" to sender
    }
}
