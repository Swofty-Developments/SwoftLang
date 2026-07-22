// A Map<Player, V> rejects a non-Player key.
function record(scores: Map<Player, Integer>) {
    set scores at "steve" to 1
}
