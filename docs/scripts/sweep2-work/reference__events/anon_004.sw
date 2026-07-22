Player {
    on_chat {
        if message contains "spoiler" {
            cancel event
            spawn warn_later(player)
        }
    }
}

async function warn_later(p: Player) {
    wait 1 seconds
    send "<red>No spoilers in chat!" to p
}
