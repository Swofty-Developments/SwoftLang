// reading a property a typed event does not have suggests the nearest real
// one ('attackr' -> 'attacker' on EntityDamage).
event EntityDamage {
    execute {
        send "hit by ${event.attackr}" to all
    }
}
