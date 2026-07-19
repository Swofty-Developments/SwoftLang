command "label" {
    execute {
        if sender is a Player {
            set label to "player"
        }
        send uppercase(label) to sender
    }
}
