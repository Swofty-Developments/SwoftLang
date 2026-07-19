event PlayerCastRod {
    execute {
        if player.world.time > 100000 {
            send "<gray>The fish are asleep." to player
            cancel event
        }
    }
}
