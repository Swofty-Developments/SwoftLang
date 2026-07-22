command "interp" {
    execute {
        set n to 41
        set word to "swoft"
        send "next is ${n + 1}"
        send "shouting: ${uppercase(word)}"
        if sender is a Player {
            send "you are at y=${sender.location.y}"
        }
    }
}
