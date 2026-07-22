struct Duel {
    @EventReceiver a: Player
    arena: Location

    a {
        on_death { teleport a to arena }      // only for this duel's player `a`
    }
}

persistent duels: map<String, Duel> = new_map()
