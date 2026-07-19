mob "sentry" {
    type: "IRON_GOLEM"
    health: 100
}

command "sentry" {
    execute {
        // in_front_of(player, distance) is a Location: 'distance' blocks ahead of the eye line
        spawn mob "sentry" at in_front_of(sender, 3) as g
        set g.glowing to true
        set g.gravity to false
        send "spawned ${g.uuid}" to sender
    }
}
