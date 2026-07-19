// on_attack_entity(player, target): target is fixed to Entity, so it cannot be
// used where a Player is required (send target must be a player).
item "wand" {
    material: "STICK"
    on_attack_entity(player, target) {
        send "you hit it" to target
    }
}
