// a settable typed event property still rejects a wrong-typed write:
// EntityDamage.damage is a Double, so a String write is a type error.
event EntityDamage {
    execute {
        set event.damage to "lots"
    }
}
