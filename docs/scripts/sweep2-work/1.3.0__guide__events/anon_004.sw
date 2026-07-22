Player {
    on_chat {
        if message contains "badword" {
            send "<red>Watch your language." to player
            cancel event
            halt
        }
        set message to "[chat] ${message}"
    }
}
