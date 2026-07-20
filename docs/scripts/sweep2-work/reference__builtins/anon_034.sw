command "nova" {
    execute {
        if sender is a Player {
            set folks to players_in_radius(sender.location, 8)
            loop folks as p {
                send "<aqua>caught in the blast" to p
            }
            send "blocks in range: ${length(blocks_in_radius(sender.location, 3))}" to sender
        }
    }
}
