persistent kills for Player: Integer = 0

Mob {
    on_death {
        if killer exists {
            set k to player(killer.uuid)
            if k exists {
                set kills for k to (kills for k) + 1
                send "<gold>${mob.custom_id} down — ${kills for k} kills" to k
            }
        }
    }
}
