Entity {
    on_hit {
        if attacker exists {
            // attack cooldown: record the swing tick for the next hit's charge
            set attacker.tags.last_swing to attacker.alive_ticks

            // crit: falling, airborne, not sprinting -> the sparkle
            if attacker.fall_distance > 0.0 and not attacker.on_ground and not attacker.is_sprinting {
                spawn particle "crit" at entity.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
            }

            // knockback: base + sprint bonus, scaled by the target's resistance
            set sprint_bonus to 0.0
            if attacker.is_sprinting {
                set sprint_bonus to 1.0
            }
            set kb_resist to entity.knockback_resistance
            set strength to (0.4 + sprint_bonus * 0.5) * (1.0 - kb_resist)
            knock entity away from attacker.location with strength strength
        }
    }
}
