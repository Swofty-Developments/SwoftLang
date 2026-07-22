command "flow" {
    execute {
        // if / else if / else
        set x to 7
        if x = 5 {
            send "five" to sender
        } else if x = 7 {
            send "seven" to sender
        } else {
            send "other" to sender
        }

        // counted loop; optional counter runs 1..N
        loop 3 times as i {
            send "iteration ${i}" to sender
        }
        loop 3 times {
            send "again" to sender
        }

        // while (runtime guard stops runaway loops at 100,000 iterations)
        set n to 3
        while n > 0 {
            set n to n - 1
        }

        // iterate a list
        loop all_players() as p {
            send "hi ${p.name}" to p
        }
        loop all players as p {                   // sugar for all_players()
            send "hey ${p.name}" to p
        }
        loop first 5 of all_players() as p {      // cap the iteration count
            send "you're early" to p
        }

        halt                                       // stop this script run
        send "never reached" to sender
    }
}
