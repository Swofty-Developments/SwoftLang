command "reset-prices" {
    execute {
        set prices to { "diamond": 800, "iron": 40 }

        set total to 0
        loop prices.values as v {
            set total to total + v
        }
        send "total value ${total}" to sender

        prices.clear()
        send "cleared, size ${prices.size}" to sender
    }
}
