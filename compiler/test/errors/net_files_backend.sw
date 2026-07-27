// v1.10.0 §1: 'mode: network' needs a backend every server can reach.
storage {
    backend: files "data/game"
    mode: network
    flush: every 30 seconds
}

persistent pot: Integer = 0
