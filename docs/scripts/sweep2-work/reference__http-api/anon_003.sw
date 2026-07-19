api "/countdown/:player" {
    method: POST
    execute {
        set target to player(request.params.player)
        if target exists {
            loop 3 times as i {
                send "<yellow>${4 - i}..." to target
                wait 1 seconds
            }
            send "<lime>Go!" to target
            reply with "done"
        } else {
            reply code 404 with "player offline"
        }
    }
}
