command "kills" {
    execute {
        set kills to { "alice": 10, "bob": 25, "carol": 7 }

        set ranked to sort_by_value_desc(kills)   // highest kills first
        loop ranked as name -> n {
            send "${name}: ${n}" to sender
        }
    }
}
