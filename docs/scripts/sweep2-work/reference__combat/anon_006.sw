on EntityDamage {
    set attacker to event.attacker
    if attacker exists {
        // crit: falling, airborne, not sprinting -> 1.5x + the sparkle
        if attacker.fall_distance > 0.0 and not attacker.on_ground and not attacker.is_sprinting {
            set event.damage to event.damage * 1.5
            spawn particle "crit" at event.entity.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
        }
    }
}
