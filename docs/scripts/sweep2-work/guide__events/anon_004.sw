event PlayerChat {
    execute {
        if event.message contains "spoiler" {
            cancel event
            spawn warn_later(event.player)
        }
    }
}

async function warn_later(p: Player) {
    wait 1 seconds
    send "<red>No spoilers in chat!" to p
}
