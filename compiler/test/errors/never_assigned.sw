command "never" {
    execute {
        send "value is ${counter}" to sender
        set x to counter + 1
    }
}
