event EntityShoot {
    execute {
        // 'power' and 'spread' have setters in the catalog, so they are writable
        set event.power to 1.5
        set event.spread to 0.0
        send "line out: ${event.projectile} towards ${event.to}" to all
    }
}
