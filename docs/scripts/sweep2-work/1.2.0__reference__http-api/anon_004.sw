api "/restart-countdown" {
    method: POST
    execute {
        reply with "countdown started"
        async {
            loop 3 times as i {
                broadcast "<red>Restarting in ${4 - i}..."
                wait 1 seconds
            }
        }
    }
}
