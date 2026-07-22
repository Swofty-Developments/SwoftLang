Entity {
    on_hit(attacker) {
        // honour a short custom i-frame window: ignore hits while it is live
        set iframe to this.invulnerable_ticks
        if iframe > 0 {
            cancel event
            return
        }
        // count hits taken on the victim's own scratch state
        set hits to this.tags.hits_taken otherwise 0
        set this.tags.hits_taken to hits + 1
    }
}
