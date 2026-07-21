item "folded_blade" {
    material: "IRON_SWORD"
    amount: 1 + 1
    attributes: {
        speed: 1.0 / 20
        attack_damage: 50 * 2
    }
}

mob "folded_ghoul" {
    type: "ZOMBIE"
    health: 100 * 2
    damage: 30 - 5
    speed: 3.0 / 10.0
    drops {
        item "folded_blade" chance 5.0 / 100.0 amount 1 + 1
    }
}
