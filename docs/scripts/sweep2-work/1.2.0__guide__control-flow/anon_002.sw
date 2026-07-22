command "countdown" {
    execute {
        loop 5 times as i {
            send "count ${i}" to sender
        }
        loop all players as p {
            send "hello ${p.name}" to p
        }
    }
}
