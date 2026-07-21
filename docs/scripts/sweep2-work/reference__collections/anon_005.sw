command "list-query" {
    execute {
        set nums to [3, 1, 2]

        if nums contains 3 {
            send "has 3" to sender
        }
        set up to sorted nums
        set ranked to sorted nums by function(n: Integer) { return 0 - n }
        set down to reversed nums
        send "sorted ${up.size}, ranked ${ranked.size}, reversed ${down.size}" to sender
    }
}
