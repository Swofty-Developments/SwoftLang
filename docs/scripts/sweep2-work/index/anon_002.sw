persistent kills for Player: Integer = 0

event MobDeath {
    execute {
        if event.killer exists {
            set kills for event.killer to kills for event.killer + 1
            send "<yellow>${kills for event.killer} kills" to event.killer
        }
    }
}
