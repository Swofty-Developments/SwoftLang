scoreboard "main" { title: "<gold>Stats" lines { line "<gray>hi" } }
bossbar "objective" { text: "<yellow>Go" progress: 0.5 color: yellow style: progress }

command "everyone" {
    execute {
        show scoreboard "main" to all
        show bossbar "objective" to all_players()
    }
}
