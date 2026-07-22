command "terse" {
    execute {
        set x to 7
        if x > 5 send "big" to sender
        else if x = 5 send "exact" to sender
        else halt

        loop 3 times as i send "i = ${i}" to sender
    }
}
