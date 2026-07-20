npc "sentry" {
    location: location(0, 64, 0)
    skin: "Notch"
    viewable: false
}

command "reveal" {
    execute {
        show npc "sentry" to sender
        show npc "sentry" to all
        hide npc "sentry" from sender
    }
}
