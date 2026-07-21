command "list-methods" {
    execute {
        set nums to [3, 1, 2]

        set idx to nums.index_of(2) otherwise 0 - 1
        set joined to nums.joined(", ")
        set evens to nums.filtered(function(n: Integer) { return n % 2 == 0 })
        set doubled to nums.mapped(function(n: Integer) { return n * 2 })
        set top to nums.max_by(function(n: Integer) { return n }) otherwise 0
        set some to nums.taken(2)
        send "idx ${idx}, joined ${joined}, top ${top}" to sender
        send "evens ${evens.size}, doubled ${doubled.size}, some ${some.size}" to sender
    }
}
