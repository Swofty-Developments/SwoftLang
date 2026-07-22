command "hello" {
    description: "Say hello"

    execute {
        send "<green>Hello, ${sender}!" to sender
    }
}
