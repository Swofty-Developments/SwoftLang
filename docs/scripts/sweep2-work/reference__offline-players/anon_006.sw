command "census" {
    execute {
        loop all_seen_players() as p {
            send "${p.name} <gray>last seen ${p.last_seen}</gray>" to sender
        }
    }
}
