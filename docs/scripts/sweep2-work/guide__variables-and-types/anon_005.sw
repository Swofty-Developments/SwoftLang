command "checks" {
    execute {
        set x to 7
        set name to "Swofty"
        if x is a Number {
            send "x is a number"
        }
        if name is not a Number {
            send "name is not a number"
        }
        if sender is a Player {
            send "ping: ${sender.latency}ms"
        }
    }
}
