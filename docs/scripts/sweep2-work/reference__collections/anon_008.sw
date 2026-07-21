command "map-methods" {
    execute {
        set scores to { "alice": 10, "bob": 7 }
        scores.put_all({ "dan": 1 })

        set safe to scores.get_or("zoe", 0)
        set byval to scores.sorted_by_value_desc()
        set bykey to scores.sorted_by(function(k: String, v: Integer) { return v })
        send "safe ${safe}, keys ${keys of scores}, values ${values of scores}" to sender
        send "byval ${byval.size}, bykey ${bykey.size}" to sender
    }
}
