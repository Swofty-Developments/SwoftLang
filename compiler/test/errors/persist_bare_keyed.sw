persistent kills for Player: Integer = 0

command "k" {
    execute {
        set count to kills
        send "${count}" to sender
    }
}
