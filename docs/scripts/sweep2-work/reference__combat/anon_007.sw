on EntityDamage {
    set victim to event.entity
    set raw to event.damage

    // i-frames: strongest-hit-wins inside the 10-tick window
    set iframe to invulnerable_ticks(victim)
    set last_amt to victim.tags.last_damage otherwise 0.0
    if iframe > 0 and raw <= last_amt {
        cancel event
        return
    }
    set incoming to raw
    if iframe > 0 {
        set incoming to raw - last_amt
    }

    // armour + toughness, read straight off the victim's attributes
    set armor to attribute(victim, "armor")
    set toughness to attribute(victim, "armor_toughness")
    set effective to armor - incoming / (2.0 + toughness / 4.0)
    set reduction to clamp(effective, armor * 0.2, 20.0)
    set dmg to incoming * (1.0 - reduction / 25.0)

    set victim.tags.last_damage to dmg
    set event.damage to dmg
}
