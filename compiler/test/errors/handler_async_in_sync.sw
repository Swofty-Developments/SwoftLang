// handler bodies are sync-colored; 'wait' is an async-only operation.
item Wand {
    material: "STICK"
    on_right_click {
        wait 1 seconds
        send "done" to player
    }
}
