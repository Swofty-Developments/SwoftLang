on EntityDamage {
    set victim to event.entity
    // simple flat mitigation off the victim's armor property, committed back to the event
    set event.damage to max(0.0, event.damage * (1.0 - victim.armor / 25.0))
}
