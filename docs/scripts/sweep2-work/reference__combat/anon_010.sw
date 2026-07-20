on EntityDamage {
    set victim to event.entity
    set dmg to event.damage * (1.0 - victim.armor / 25.0)
    set event.damage to max(0.0, dmg)
}
