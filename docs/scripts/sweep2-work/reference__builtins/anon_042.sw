command "leaderboard" {
    execute {
        set nums to [3, 1, 2]
        set up to sort(nums)              // [1, 2, 3]
        set down to reverse(nums)         // [2, 1, 3]
        send "sizes ${length(up)} ${length(down)}" to sender

        set scores to [10, 5, 20]
        set ranked to sort_by_desc(scores, function(n) return n)
        loop ranked as s {
            send "score ${s}" to sender
        }
        set top to max_by(scores, function(n) return n) otherwise 0
        send "top ${top}" to sender
    }
}
