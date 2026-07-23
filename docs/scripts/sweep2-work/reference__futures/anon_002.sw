async function log_metrics(p: Player) {
    wait 10 millis
    return 1
}

command "ping" {
    execute {
        if sender is a Player {
            spawn log_metrics(sender)   // statement form → result discarded
            send "pong" to sender
        }
    }
}
