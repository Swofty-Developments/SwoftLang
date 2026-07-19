storage {
    backend: files "data/a"
}

storage {
    backend: sqlite "data/b.db"
    flush: every 5 seconds
}

persistent total_joins: Integer = 0
