command "list-mut" {
    execute {
        set nums to [3, 1, 2]
        add 4 to nums
        remove 1 from nums
        add 9 to nums
        send "size ${size of nums}" to sender
    }
}
