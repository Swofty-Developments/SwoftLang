command "find" {
    execute {
        set target to player("Notch")
        if target exists {
            send "hi ${target.name}" to sender
        } else {
            send "<red>Notch is not online" to sender
        }
    }
}
