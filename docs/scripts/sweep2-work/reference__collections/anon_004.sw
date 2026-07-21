command "list-mut" {
    execute {
        set nums to [3, 1, 2]
        nums.add(4)
        nums.remove(1)
        nums.add(9)
        send "size ${nums.size}" to sender
    }
}
