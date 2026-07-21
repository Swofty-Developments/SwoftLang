Player {
    on_chat(message) {
        if message contains "badword" {
            cancel event
            send "<red>Watch your language" to this
        }
    }
}
