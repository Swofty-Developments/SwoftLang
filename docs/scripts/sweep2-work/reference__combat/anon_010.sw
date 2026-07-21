Entity {
    on_hit(attacker) {
        if attacker exists {
            set kb_resist to this.knockback_resistance
            knock this away from attacker.location with strength (0.5 * (1.0 - kb_resist))
        }
    }
}
