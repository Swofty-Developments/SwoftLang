// on_attack_entity: target is fixed to Entity, so it cannot be
// used where a Player is required (send target must be a player).
item Wand {
    material: "STICK"
    on_attack_entity {
        send "you hit it" to target
    }
}
