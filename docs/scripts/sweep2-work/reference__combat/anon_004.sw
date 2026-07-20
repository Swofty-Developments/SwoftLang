on EntityDamage {
    set attacker to event.attacker
    if attacker exists {
        knock event.entity away from attacker.location with strength 0.5
    }
}
