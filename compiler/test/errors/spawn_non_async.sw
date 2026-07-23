function plain(n: Integer) {
    return n + 1
}

Player {
    on_join {
        set f to spawn plain(3)
    }
}
