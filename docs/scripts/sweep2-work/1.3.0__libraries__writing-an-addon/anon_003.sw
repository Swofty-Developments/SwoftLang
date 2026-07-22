import "titles"

command "duel" {
    execute {
        spawn countdown(sender, 3, function(p: Player) {
            send "<green>The duel is on." to p
            teleport p to location(0.5, 80.0, 0.5)
        })
        send "<gray>Get ready..." to sender
    }
}
