// on_clicked is not a mob handler; the checker suggests the nearest valid name.
mob "ghoul" {
    type: "ZOMBIE"
    on_clicked {
        send "hi" to player
    }
}
