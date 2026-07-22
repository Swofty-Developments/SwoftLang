command "terse" {
    execute {
        // any body can be exactly one brace-free statement
        set x to 7
        if x > 5 send "big" to sender
        else if x = 5 send "exact" to sender
        else halt

        loop 3 times as i send "i = ${i}" to sender
        async send "from a task" to sender

        // a dangling else binds to the nearest if
        if x > 0 if x > 100 send "huge" to sender
        else send "positive, not huge" to sender
    }
}
