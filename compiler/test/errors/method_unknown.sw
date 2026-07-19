command "mu" {
    execute {
        set nums to [1, 2, 3]
        set x to nums.frobnicate(2)
        send "${x}" to sender
    }
}
