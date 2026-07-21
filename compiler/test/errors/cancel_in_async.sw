Player {
    on_chat {
        async {
            wait 5 ticks
            cancel event
        }
    }
}
