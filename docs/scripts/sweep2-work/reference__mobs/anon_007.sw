mob Zombie {
    type: "ZOMBIE"
    viewable: false

    tags: { hits: map<Player, Integer> }      // typed, keyed by Player

    on_hit {
        if attacker exists {
            set mob.tags.hits[attacker] to (mob.tags.hits[attacker] otherwise 0) + 1
        }
    }
}
