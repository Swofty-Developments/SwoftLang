command "who" {
    execute {
        send "There are ${length(all_players())} players online" to sender
        loop all_players() as p {
            send "<gray>- ${p.name}" to sender
        }
    }
}
