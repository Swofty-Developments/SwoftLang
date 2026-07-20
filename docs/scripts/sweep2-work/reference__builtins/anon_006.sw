command "logs" {
    execute {
        set natural to ln(e())                     // 1.0
        set order to log10(1000.0)                 // 3.0
        set bits to log(256.0, 2.0)                // 8.0
        send "${natural} ${order} ${bits}" to sender
    }
}
