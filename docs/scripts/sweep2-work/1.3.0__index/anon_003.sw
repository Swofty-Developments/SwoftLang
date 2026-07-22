command "crate" {
    execute async {
        send "<gray>Opening your crate..." to sender
        wait 3 seconds
        send "<green>You won a diamond!" to sender
    }
}
