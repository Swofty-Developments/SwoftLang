command "bank" {
    execute {
        send "Balance: ${format_number(1234567)} coins" to sender
    }
}
