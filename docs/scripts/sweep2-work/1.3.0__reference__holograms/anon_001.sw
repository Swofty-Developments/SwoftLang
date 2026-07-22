hologram "rules" {
    location: location(4, 70, 4)
    billboard: fixed
    lines {
        line "<aqua><bold>Server Rules"
        line "<gray>1. Be nice"
        line "<gray>2. No griefing"
    }
}

command "showrules" {
    execute {
        show hologram "rules" to all
    }
}
