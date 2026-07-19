// writing a read-only typed event property is rejected (design A1: ro props
// error on write). damage_type is a read-only String on EntityDamage.
event EntityDamage {
    execute {
        set event.damage_type to "fire"
    }
}
