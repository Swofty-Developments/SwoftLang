command "me" {
    execute {
        set nums to [1, 2, 3]
        set x to nums.add(4)
        send "${x}" to sender
    }
}
