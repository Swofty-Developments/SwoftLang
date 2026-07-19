persistent kills for Player: Integer = 0

command "top" {
    execute {
        loop all players as kills {
            send "hi" to sender
        }
    }
}
