async function countdown(target: Player, from: Integer) {   // 1. async function
    loop from times as i {
        send "<yellow>${from - i + 1}..." to target
        wait 1 seconds                                      // 2. wait
    }
    send "<lime>Go!" to target
}

command "race" {
    execute {
        spawn countdown(sender, 3)                          // 3. spawn
        send "countdown started" to sender
    }
}

Player {
    on_join {
        async {                                             // 4. async block
            wait 60 ticks
            send "<gold>Tip: type /help to get started" to player
        }
    }
}
