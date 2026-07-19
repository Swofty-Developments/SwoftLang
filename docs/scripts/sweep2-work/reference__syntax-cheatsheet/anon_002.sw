event PlayerChat {
    priority: 0

    execute {
        set event.message to "[Filtered] ${event.message}"
        if event.message contains "badword" {
            cancel event
        }
    }
}
