command "count" {
    execute {
        send "letters: ${length(sender.name)}" to sender
        send "online: ${length(all_players())}" to sender
    }
}
