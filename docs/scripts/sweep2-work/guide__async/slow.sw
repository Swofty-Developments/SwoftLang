command "slow" {
    execute {
        send "counting down..." to sender
        wait 3 seconds
        send "done" to sender
    }
}
