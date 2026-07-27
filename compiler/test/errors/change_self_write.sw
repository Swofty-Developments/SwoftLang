// v1.10.0 §5 layer 2: a handler that writes its own value at its own key
// re-enters itself with nothing in between to converge.
storage {
    backend: files "data/game"
}

persistent pot: Integer = 0 {
    on_change {
        set pot to new + 1
    }
}
