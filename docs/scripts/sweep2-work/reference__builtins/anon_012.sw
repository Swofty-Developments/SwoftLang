command "pct" {
    execute {
        send "${format_decimals(3.14159, 2)}" to sender       // 3.14
        send "${format_decimals(1.0 / 3.0, 3)}" to sender     // 0.333
    }
}
