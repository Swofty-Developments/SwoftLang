// A map<Player, V> rejects a non-Player key.
function record(scores: map<Player, Integer>) {
    map_set(scores, "steve", 1)
}
