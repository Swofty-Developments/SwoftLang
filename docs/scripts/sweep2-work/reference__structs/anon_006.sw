struct Duel {
    @EventReceiver a: Player
    @EventReceiver b: Player
    arena: Location
    score: map<Player, Integer>

    a {                          // the field name opens its handler block
        on_death {               // Player's vocabulary, because a : Player
            // full struct context is in scope as bare names: a, b, arena, score
            set score at b to (score[b] otherwise 0) + 1
            teleport a to arena
            broadcast "<yellow>${b.name} takes the lead"
        }
    }

    b {
        on_death {
            set score at a to (score[a] otherwise 0) + 1
            teleport b to arena
            broadcast "<yellow>${a.name} takes the lead"
        }
    }
}
