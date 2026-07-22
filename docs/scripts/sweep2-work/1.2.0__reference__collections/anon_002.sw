command "list-expr" {
    execute {
        set nums to [3, 1, 2]

        if nums.contains(3) {
            send "has 3" to sender
        }
        set idx to nums.index_of(2) otherwise 0 - 1
        set third to nums.get(2) otherwise 0
        set joined to nums.joined(", ")
        send "third ${third}, idx ${idx}, joined ${joined}" to sender

        set sorted to nums.sorted()
        set ranked to nums.sorted_by(function(n: Integer) { return n })
        set evens to nums.filtered(function(n: Integer) { return n % 2 == 0 })
        set doubled to nums.mapped(function(n: Integer) { return n * 2 })
        set top to nums.max_by(function(n: Integer) { return n }) otherwise 0
        set some to nums.taken(2)
        send "sorted ${sorted.size}, evens ${evens.size}, doubled ${doubled.size}" to sender
        send "top ${top}, some ${some.size}" to sender
    }
}
