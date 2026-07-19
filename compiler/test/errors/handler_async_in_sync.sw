// handler bodies are sync-colored; 'wait' is an async-only operation.
item "wand" {
    material: "STICK"
    on_right_click(player) {
        wait 1 seconds
        send "done" to player
    }
}
