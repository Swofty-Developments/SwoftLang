Entity {
    on_hit(attacker) {
        if attacker exists {
            // crit: falling, airborne, not sprinting -> the sparkle
            if attacker.fall_distance > 0.0 and not attacker.on_ground and not attacker.is_sprinting {
                spawn particle "crit" at this.location count 8 offset 0.4, 0.6, 0.4 speed 0.1 to all
            }
        }
    }
}
