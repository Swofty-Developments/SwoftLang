Entity {
    on_hit {
        if attacker exists {
            knock entity away from attacker.location with strength 0.5
        }
    }
}
