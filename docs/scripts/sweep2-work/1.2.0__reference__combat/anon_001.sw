Entity {
    on_hit(attacker) {
        // veto a hit entirely — this is the victim, attacker is the source
        if this.tags.invulnerable exists {
            cancel event
        }
    }
}
