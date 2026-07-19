command "x" {
    execute {
        set people to all_players()
        set ranked to sort_by(people, function(p: Player) return p.location)
        send "done" to sender
    }
}
