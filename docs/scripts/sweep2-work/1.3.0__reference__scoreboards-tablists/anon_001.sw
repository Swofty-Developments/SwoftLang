command "sb" {
    execute {
        show scoreboard "main" to sender      // create lazily + add viewer
        update scoreboard for sender          // force one refresh now
        hide scoreboard from sender           // remove whatever board they see
    }
}
