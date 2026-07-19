command "roll" {
    execute {
        loop all players as p {
            send "you rolled ${random(1, 100)}" to p
        }
    }
}
