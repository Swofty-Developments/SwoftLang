command "radio" {
    execute {
        play song "cafe.nbs" to sender
        send "<gray>Now playing." to sender
    }
}
