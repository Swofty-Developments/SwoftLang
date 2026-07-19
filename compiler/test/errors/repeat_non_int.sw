// 'repeat N times' requires a positive Integer count
command "bad" {
    execute {
        repeat "five" times {
            send "tick" to sender
        }
    }
}
