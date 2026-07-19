event EntityDamage {
    execute {
        set event.damage to event.damage * 2.0
        send "${event.entity} took ${event.damage} (${event.damage_type})" to all
        if event.attacker exists {
            send "attacker: ${event.attacker}" to all
        }
        if event.damage > 100.0 {
            cancel event
        }
    }
}
