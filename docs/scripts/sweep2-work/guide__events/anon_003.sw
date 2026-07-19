event PlayerChat {
    priority: 0

    execute {
        if event.message contains "badword" {
            send "<red>Watch your language." to event.player
            cancel event
            halt
        }
        set event.message to "[chat] ${event.message}"
    }
}
