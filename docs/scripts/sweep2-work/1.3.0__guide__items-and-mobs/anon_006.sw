persistent mob_kills for Player: Integer = 0

Mob {
    on_death {
        if killer exists {
            set k to player(killer.uuid)
            if k exists {
                set mob_kills for k to (mob_kills for k) + 1
                send "<gold>Kill #${mob_kills for k}: ${mob.custom_id}" to k
            }
        }
    }
}
