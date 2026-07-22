persistent kills for Player: Integer = 0

command "stats" {
    execute {
        send "kills: ${kills}" to sender
    }
}
