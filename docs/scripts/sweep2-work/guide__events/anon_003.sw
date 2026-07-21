Player {
    on_chat {
        if message contains "badword" {
            cancel event
            send "<red>Watch your language" to player
        }
    }
}
