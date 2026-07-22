persistent kills for Player: Integer = 0

Mob {
    on_death(killer) {
        if killer exists {
            set k to player(killer.uuid)
            if k exists {
                set kills for k to (kills for k) + 1
                send "<gold>${this.custom_id} down — ${kills for k} kills" to k
            }
        }
    }
}
