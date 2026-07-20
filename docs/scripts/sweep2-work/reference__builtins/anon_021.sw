command "poke" {
    execute {
        set target to player("Notch")
        if target exists {
            send "<lime>Poke!" to target
        } else {
            send "<gray>Notch is not online" to sender
        }

        // or supply a fallback:
        set victim to player("Notch") otherwise sender
        send "gotcha" to victim
    }
}
