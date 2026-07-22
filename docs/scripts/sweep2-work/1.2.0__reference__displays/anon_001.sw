command "label" {
    execute {
        set d to spawn_text_display("<gold><bold>Item Shop", location(0.5, 82.0, 0.5))
        set d.billboard to "center"
        set d.scale to 1.5
        set d.background to "#80000000"
    }
}
