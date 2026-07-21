command "reset-prices" {
    execute {
        set prices to { "diamond": 800, "iron": 40 }

        set total to 0
        loop values of prices as v {
            set total to total + v
        }
        send "total value ${total}" to sender

        clear prices
        send "cleared, size ${size of prices}" to sender
    }
}
