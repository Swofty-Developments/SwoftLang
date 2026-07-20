command "bad" {
    execute {
        set v to vec(1.0, 2.0, 3.0)
        set v.length to 9.0
        send "done" to sender
    }
}
