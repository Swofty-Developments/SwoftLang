command "under" {
    execute {
        send "you stand on ${block_at(location(sender.location.x, sender.location.y - 1, sender.location.z))}" to sender
    }
}
