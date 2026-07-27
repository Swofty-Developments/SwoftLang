// v1.10.0 §4: a collection reacts per ENTRY, so it wants 'on_entry_change'.
storage {
    backend: files "data/game"
}

persistent leaderboard: Map<String, Integer> = new_map() {
    on_change {
        broadcast "leaderboard changed"
    }
}
