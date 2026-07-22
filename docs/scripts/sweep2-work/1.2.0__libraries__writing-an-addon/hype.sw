import "titles"

command "hype" {
    execute {
        announce(sender, "Boss incoming")
        announce_all("Sudden death!")
        set_title_style(function(text: String) return "<red><bold>${text}")
        spawn countdown(sender, 3, function(p: Player) send "<green>fight!" to p)
    }
}
