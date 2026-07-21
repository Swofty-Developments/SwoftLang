// A handler takes no parameter list — the receiver and the event's values
// are bound as bare variables in scope.
item "wand" {
    material: "STICK"
    on_right_click(player) {
        send "hi" to player
    }
}
