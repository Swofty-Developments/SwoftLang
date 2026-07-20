on EntityDamage {
    set victim to event.entity
    set iframe to invulnerable_ticks(victim)
    set last to victim.tags.last_damage otherwise 0.0
    // honour the 10-tick window: a weaker-or-equal hit inside it is ignored
    if iframe > 0 and event.damage <= last {
        cancel event
        return
    }
    set victim.tags.last_damage to event.damage
}
