Entity {
    on_hit {
        // veto a hit entirely — entity is the victim, attacker is the source
        if entity.tags.invulnerable exists {
            cancel event
        }
    }
}
