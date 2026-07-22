Player {
    on_chat {
        set message to "[Filtered] ${message}"
        if message contains "badword" {
            cancel event
        }
    }
}
