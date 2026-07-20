persistent kills for Player: Integer = 0

event MobDeath {
    execute {
        if event.killer exists {
            set kills for event.killer to (kills for event.killer) + 1
            send "<gold>${event.mob.custom_id} down — ${kills for event.killer} kills" to event.killer
        }
    }
}

event MobDamage {
    execute {
        if event.mob.custom_id is "lost_sheep" {
            cancel event
        }
    }
}
