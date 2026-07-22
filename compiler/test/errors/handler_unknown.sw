// on_clicked is not a mob handler; the checker suggests the nearest valid name.
mob Ghoul {
    type: "ZOMBIE"
    on_clicked {
        send "hi" to player
    }
}
