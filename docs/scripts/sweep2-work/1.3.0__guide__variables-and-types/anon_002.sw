command "profile" {
    execute {
        set coins to 500
        set rank to "Knight"
        send "<gold>${rank} <white>— ${coins} coins" to sender
    }
}
