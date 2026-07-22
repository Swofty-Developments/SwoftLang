command "sparkle" {
    execute {
        spawn particle "FLAME" at sender.location count 40 offset 0.5, 0.5, 0.5 speed 0.01
        spawn particle "HEART" at sender.location count 3 to sender
    }
}
