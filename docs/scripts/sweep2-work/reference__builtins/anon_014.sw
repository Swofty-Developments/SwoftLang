command "clip" {
    execute {
        send "Hello, World".first_chars(5) to sender          // Hello
        send "Hello, World".last_chars(5) to sender           // World
    }
}
