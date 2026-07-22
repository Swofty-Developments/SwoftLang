Entity {
    on_hit {
        // honour a short custom i-frame window: ignore hits while it is live
        set iframe to entity.invulnerable_ticks
        if iframe > 0 {
            cancel event
            return
        }
        // count hits taken on the victim's own scratch state
        set hits to entity.tags.hits_taken otherwise 0
        set entity.tags.hits_taken to hits + 1
    }
}
