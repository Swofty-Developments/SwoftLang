// v1.10.0 §1: a per-process sqlite file can't hold a lease two servers can see.
storage {
    backend: sqlite "data/game.db"
    mode: network
    flush: every 30 seconds
}

persistent pot: Integer = 0
