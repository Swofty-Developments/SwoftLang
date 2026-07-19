persistent mob_kills for Player: Integer = 0

event MobDeath {
    execute {
        if event.killer exists {
            set mob_kills for event.killer to (mob_kills for event.killer) + 1
            send "<gold>Kill #${mob_kills for event.killer}: ${event.mob.custom_id}" to event.killer
        }
    }
}
