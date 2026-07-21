command "accessors" {
    execute {
        set nums to [10, 20, 30]
        send "size ${size of nums}, empty ${nums.is_empty}" to sender
        send "first ${first of nums otherwise 0}, last ${last of nums otherwise 0}" to sender
    }
}
