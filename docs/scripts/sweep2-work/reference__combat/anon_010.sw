Entity {
    on_hit {
        if attacker exists {
            set kb_resist to entity.knockback_resistance
            knock entity away from attacker.location with strength (0.5 * (1.0 - kb_resist))
        }
    }
}
