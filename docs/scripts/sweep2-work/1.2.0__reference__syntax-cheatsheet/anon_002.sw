Player {
    on_chat(message) {
        set message to "[Filtered] ${message}"
        if message contains "badword" {
            cancel event
        }
    }
}
