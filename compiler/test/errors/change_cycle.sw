// v1.10.0 §5 layer 2: coins -> leaderboard -> coins. The second hop is reached
// through a function call, so the graph is interprocedural.
storage {
    backend: files "data/game"
}

persistent coins for Player: Integer = 0 {
    on_change {
        set leaderboard at player.name to new
    }
}

persistent leaderboard: Map<String, Integer> = new_map() {
    on_entry_change {
        bump(key)
    }
}

function bump(name: String) {
    set found to player(name)
    if found exists {
        grant 1 coins to found
    }
}
