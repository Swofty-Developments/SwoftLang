command "map-methods" {
    execute {
        set scores to { "alice": 10, "bob": 7 }
        scores.set("carol", 3)
        scores.delete("bob")
        scores.put_all({ "dan": 1 })

        set alice to scores.get("alice") otherwise 0
        set safe to scores.get_or("zoe", 0)
        if scores.has("alice") {
            send "has alice" to sender
        }
        set byval to scores.sorted_by_value_desc()
        set bykey to scores.sorted_by(function(k: String, v: Integer) { return v })
        send "map ${scores.size}, keys ${scores.keys.size}, values ${scores.values.size}" to sender
        send "alice ${alice}, safe ${safe}, byval ${byval.size}, bykey ${bykey.size}" to sender
    }
}
