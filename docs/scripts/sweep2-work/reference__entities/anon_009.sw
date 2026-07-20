mob "zombie" {
    type: "ZOMBIE"
    viewable: false                          // spawns hidden — handed out per player

    tags { hits: map<Player, Integer> }      // typed per-entity state, keyed by player

    on_hit(attacker) {
        if attacker exists {
            set mob.tags.hits[attacker] to (mob.tags.hits[attacker] otherwise 0) + 1
            set count to mob.tags.hits[attacker] otherwise 0

            // only this attacker sees this nameplate
            set name of mob to "<red>Zombie <gray>${count}/5" for attacker

            if count >= 5 {
                hide mob from attacker                    // gone for them only
                send "<green>You slew your zombie!" to attacker
            }
        }
    }
}

on PlayerJoin {
    spawn mob "zombie" at in_front_of(event.player, 5) as z
    set name of z to "<red>Zombie <gray>0/5" for event.player
    show z to event.player                                // reveal it to just this player
}
