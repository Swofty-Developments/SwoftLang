command "ma" {
    execute {
        set nums to [1, 2, 3]
        set x to nums.get(1, 2) otherwise 0
        send "${x}" to sender
    }
}
