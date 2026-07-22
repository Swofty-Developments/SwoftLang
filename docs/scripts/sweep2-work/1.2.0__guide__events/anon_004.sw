Player {
    on_chat(message) {
        if message contains "badword" {
            send "<red>Watch your language." to this
            cancel event
            halt
        }
        set message to "[chat] ${message}"
    }
}
