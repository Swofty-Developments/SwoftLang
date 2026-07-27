// v1.10.0 §4: change handlers run on the TICK thread, so awaiting inside one is
// the existing colour error — the fix is an 'async { }' block.
storage {
    backend: files "data/game"
}

persistent coins for Player: Integer = 0 {
    on_change {
        set bal to await coins for player
        send "balance ${bal}" to player
    }
}
