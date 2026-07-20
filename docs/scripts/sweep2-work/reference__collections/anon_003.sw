command "list-mut" {
    execute {
        set nums to [3, 1, 2]
        nums.add(4)
        nums.add_all([5, 6])
        nums.remove(1)
        nums.insert(0, 9)
        send "size ${nums.size}" to sender
    }
}
