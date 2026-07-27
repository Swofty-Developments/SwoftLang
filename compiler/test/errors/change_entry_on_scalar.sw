// v1.10.0 §4: a scalar has no entries — it reacts as a whole with 'on_change'.
storage {
    backend: files "data/game"
}

persistent pot: Integer = 0 {
    on_entry_change {
        broadcast "pot entry changed"
    }
}
