Entity {
    on_hit(attacker) {
        if attacker exists {
            knock this away from attacker.location with strength 0.5
        }
    }
}
