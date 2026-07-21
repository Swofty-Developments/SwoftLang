command "lookup" {
    execute {
        set prices to { "diamond": 800, "iron": 40 }

        // fall back to a default
        set p to prices["gold"] otherwise 0
        send "gold costs ${p}" to sender

        // ...or narrow with 'exists'
        if prices["diamond"] exists {
            send "diamond is priced" to sender
        }
    }
}
