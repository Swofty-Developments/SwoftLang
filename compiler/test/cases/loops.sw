command "loops" {
    execute {
        loop 5 times {
            broadcast "x"
        }
        loop 2 + 3 times as i {
            send "${i}"
        }
        loop all players as p {
            teleport p to sender
        }
        while true {
            halt
        }
    }
}
