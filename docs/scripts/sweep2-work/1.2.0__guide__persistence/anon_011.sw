storage {
    backend: sqlite "data/stats.db"
    flush: every 10 seconds
}

persistent total_deaths: Integer = 0
persistent kills for Player: Integer = 0
persistent best_streak for Player: Integer = 0

command "stats" {
    description: "Your lifetime stats"

    execute {
        if sender is a Player {
            send "<gold>kills: ${kills for sender}" to sender
            send "<gold>best streak: ${best_streak for sender}" to sender
            send "<gray>server-wide deaths: ${format_number(total_deaths)}" to sender
        }
    }
}
