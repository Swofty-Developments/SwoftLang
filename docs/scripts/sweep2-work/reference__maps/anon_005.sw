command "pmap" {
    execute {
        set wins to new_map()

        set wins at sender to 10             // first insertion fixes K = Player, V = Integer
        set mine to wins[sender] otherwise 0
        send "you have ${mine}" to sender

        loop wins as who -> pts {            // key is a Player
            send "${who.name}: ${pts}" to sender
        }
    }
}
