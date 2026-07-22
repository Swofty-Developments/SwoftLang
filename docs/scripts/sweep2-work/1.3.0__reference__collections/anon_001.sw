command "accessors" {
    execute {
        set nums to [10, 20, 30]
        send "size ${nums.size}, empty ${nums.is_empty}" to sender
        send "first ${nums.first otherwise 0}, last ${nums.last otherwise 0}" to sender
    }
}
