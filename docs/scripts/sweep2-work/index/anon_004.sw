command "crate" {
    description: "Open a timed reward crate"

    execute async {
        send "<gray>Opening your crate..." to sender
        wait 3 seconds
        send "<green>You won a diamond!" to sender
        spawn announce(sender.name)
    }
}

async function announce(name: String) {
    wait 1 seconds
    send "<gold>${name} just opened a crate" to all
}
