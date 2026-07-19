event PlayerChat {
    execute {
        if event.message contains "badword" {
            cancel event
            send "<red>Watch your language" to event.player
        }
    }
}
