hologram "rules" {
    location: location(4, 70, 4)
    billboard: fixed
    lines {
        line "<aqua><bold>Server Rules"
        line "<gray>1. Be nice"
    }
}

command "showrules" {
    execute {
        show hologram "rules" to all
    }
}
