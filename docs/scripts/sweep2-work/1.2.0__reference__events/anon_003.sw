Player {
    on_chat(message) {
        if message contains "spoiler" {
            cancel event
            spawn warn_later(this)
        }
    }
}

async function warn_later(p: Player) {
    wait 1 seconds
    send "<red>No spoilers in chat!" to p
}
