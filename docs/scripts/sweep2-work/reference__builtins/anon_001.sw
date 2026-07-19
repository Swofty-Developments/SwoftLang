command "roll" {
    execute {
        send "You rolled ${random(1, 6)}" to sender
    }
}
