on EntityDamage {
    set victim to event.entity
    set armor to attribute(victim, "armor")
    set dmg to event.damage * (1.0 - armor / 25.0)
    set event.damage to max(0.0, dmg)
}
