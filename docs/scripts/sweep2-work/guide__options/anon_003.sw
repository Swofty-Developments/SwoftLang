command "title" {
    execute {
        set label to none
        set title to label otherwise "guest"
        send "title = ${title}" to sender
    }
}
