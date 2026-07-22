Entity {
    on_hit(attacker) {
        if this.type is "SHEEP" {
            cancel event                    // sheep take no damage
        }
    }
}
