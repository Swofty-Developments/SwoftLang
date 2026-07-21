// A map<Player, V> rejects a non-Player key.
function record(scores: map<Player, Integer>) {
    set scores at "steve" to 1
}
