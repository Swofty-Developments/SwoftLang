on EntityDamage {
    set victim to event.entity
    set armor to attribute(victim, "armor")
    // simple flat mitigation, then commit it back to the event
    set event.damage to max(0.0, event.damage * (1.0 - armor / 25.0))
}
