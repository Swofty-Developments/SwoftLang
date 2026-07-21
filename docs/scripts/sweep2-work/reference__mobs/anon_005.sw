mob "guardian" {
    type: "IRON_GOLEM"
    name: "<gold>Guardian"
    health: 100

    on_hit {
        if attacker exists {
            send "<red>You struck the ${mob.custom_id}!" to attacker
        }
        set mob.velocity to velocity(0, 0.5, 0)
    }
}
