command "trig" {
    execute {
        set up to sin(pi() / 2)                    // 1.0
        set angle to atan2(1.0, 1.0)               // π/4
        send "${up} ${angle}" to sender
    }
}
