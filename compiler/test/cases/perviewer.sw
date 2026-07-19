server { auth: mojang  lighting: true }
mob "zombie" {
    type: "ZOMBIE"
    viewable: false
    tags { hits: map<Player, Integer> }
    on_hit(attacker) {
        if attacker exists {
            set mob.tags.hits[attacker] to (mob.tags.hits[attacker] otherwise 0) + 1
            set name of mob to "<red>Zombie <gray>${mob.tags.hits[attacker] otherwise 0}/5" for attacker
            if (mob.tags.hits[attacker] otherwise 0) >= 5 {
                hide mob from attacker
                send "<green>You slew your zombie!" to attacker
            }
        }
    }
}
on PlayerJoin {
    spawn mob "zombie" at in_front_of(event.player, 5) as z
    set name of z to "<red>Zombie <gray>0/5" for event.player
    show z to event.player
}
