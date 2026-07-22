struct Duel {
    @EventReceiver a: Player
    @EventReceiver b: Player
    arena: Location

    a { on_chat { cancel event  broadcast "<gray>[duel] ${a.name}: ${message}" } }
    b { on_chat { cancel event  broadcast "<gray>[duel] ${b.name}: ${message}" } }
}

persistent duels: map<String, Duel> = new_map()

Player {
    on_chat {
        send "<dark_gray>(logged)" to player      // the global layer, runs first
    }
}
