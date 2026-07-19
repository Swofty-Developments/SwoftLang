// W-collections: method-call syntax for maps, lists, and Strings.
//
// Method-call EXPRESSIONS (<receiver>.<name>(args)) resolve by the receiver's
// static type; the zero-arg accessors (.size/.keys/.first/.is_empty) stay in
// property form. Mutating methods (add/set/remove/...) are bare STATEMENTS
// that mutate in place. The free builtins (map_get/sort/uppercase/...) still
// work as deprecated aliases delegating to the same runtime.

command "collections" {
    execute {
        // --- lists: mutating statements ---
        set nums to [3, 1, 2]
        nums.add(4)
        nums.add_all([5, 6])
        nums.remove(1)
        nums.insert(0, 9)

        // --- lists: pure expression methods ---
        if nums.contains(3) {
            send "has 3" to sender
        }
        set idx to nums.index_of(2) otherwise 0 - 1
        set third to nums.get(2) otherwise 0
        set joined to nums.joined(", ")
        send "size ${nums.size}, empty ${nums.is_empty}, third ${third}, idx ${idx}" to sender
        send "first ${nums.first otherwise 0}, last ${nums.last otherwise 0}, joined ${joined}" to sender

        // transforms return new lists; lambdas take the element type
        set sorted to nums.sorted()
        set ranked to nums.sorted_by(function(n: Integer) { return n })
        set evens to nums.filtered(function(n: Integer) { return n % 2 == 0 })
        set doubled to nums.mapped(function(n: Integer) { return n * 2 })
        set top to nums.max_by(function(n: Integer) { return n }) otherwise 0
        set some to nums.taken(2)
        send "sorted ${sorted.size}, ranked ${ranked.size}, evens ${evens.size}" to sender
        send "doubled ${doubled.size}, top ${top}, some ${some.size}" to sender

        // --- maps: mutating statements ---
        set scores to { "alice": 10, "bob": 7 }
        scores.set("carol", 3)
        scores.delete("bob")
        scores.put_all({ "dan": 1 })

        // --- maps: pure expression methods + accessors ---
        set alice to scores.get("alice") otherwise 0
        set safe to scores.get_or("zoe", 0)
        if scores.has("alice") {
            send "has alice" to sender
        }
        set byval to scores.sorted_by_value_desc()
        set bykey to scores.sorted_by(function(k: String, v: Integer) { return v })
        send "map ${scores.size}, keys ${scores.keys.size}, values ${scores.values.size}" to sender
        send "alice ${alice}, safe ${safe}, byval ${byval.size}, bykey ${bykey.size}" to sender

        // --- strings ---
        set greeting to "  Hello, World  "
        set clean to greeting.trimmed()
        set parts to clean.split(", ")
        set up to clean.upper()
        set rep to "ab".repeated(3)
        set starts to clean.starts_with("Hello")
        send "clean '${up}' len ${clean.length()} len2 ${clean.length}" to sender
        send "parts ${parts.size}, rep ${rep}, starts ${starts}" to sender
    }
}
