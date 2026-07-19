command "crown" {
    execute {
        set crown to spawn_item_display("GOLDEN_HELMET", sender.location)
        set crown.translation to location(0.0, 2.3, 0.0)
        set crown.scale to 0.6
        mount display crown on sender
        send "<gold>Crowned." to sender

        // a private marker: spawn for everyone, then narrow visibility
        set mark to spawn_text_display("<red>quest here", location(10.5, 70.0, 4.5))
        hide display mark from all
        show display mark to sender
    }
}
