struct Duel {
    @EventReceiver a: Player
    @EventReceiver b: Player
    arena: Location
    score: Map<Player, Integer>

    a { on_death { set score at b to (score[b] otherwise 0) + 1  teleport a to arena } }
    b { on_death { set score at a to (score[a] otherwise 0) + 1  teleport b to arena } }
}

persistent duels: Map<String, Duel> = new_map()

command "duel" {
    execute {
        if sender is a Player {
            // live the instant it lands in `duels`
            set duels at "arena-1" to Duel {
                a: sender, b: sender, arena: sender.location, score: new_map()
            }
        }
    }
}

command "endduel" {
    execute {
        delete duels at "arena-1"      // stops reacting, durably
    }
}
