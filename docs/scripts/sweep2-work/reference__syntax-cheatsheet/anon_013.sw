storage {
  backend: files "data/swoftlang"     // or: sqlite "path.db" | mysql { ... } | mongodb "uri"
  flush: every 30 seconds             // write-behind cadence (default 30s)
}

persistent total_joins: Integer = 0            // global scalar, default required
persistent kills for Player: Integer = 0       // keyed by subject

Player {
    on_join {
        set total_joins to total_joins + 1
    }
}
