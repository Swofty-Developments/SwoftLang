npc "sentry" {
    location: location(0, 64, 0)
    skin: "Notch"
    viewable: false
}

command "who_sees" {
    execute {
        loop viewers of npc "sentry" as p {
            send "<gray>You can see the sentry." to p
        }
    }
}
