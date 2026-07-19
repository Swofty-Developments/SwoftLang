// Phase 11: easy sorting builtins for lists and maps. Non-mutating; the key
// lambda drives sort_by/min_by/max_by/sort_map_by.

command "sorting" {
    execute {
        // natural ascending sort of numbers and of strings
        set nums to [3, 1, 2]
        set sorted_nums to sort(nums)
        set words to ["banana", "apple", "cherry"]
        set sorted_words to sort(words)
        set rev to reverse(nums)
        send "have ${length(sorted_nums)} ${length(sorted_words)} ${length(rev)}" to sender

        // the leaderboard form: sort by a key lambda, descending
        set scores to [10, 5, 20]
        set ranked to sort_by_desc(scores, function(n) return n)
        set ranked_asc to sort_by(scores, function(n) return n)
        set top to max_by(scores, function(n) return n)
        set low to min_by(scores, function(n) return n)
        send "top ${top otherwise 0} low ${low otherwise 0}" to sender

        // first-class map sorting: return a new map with sorted iteration order
        set kills to { "alice": 10, "bob": 25, "carol": 7 }
        set by_val to sort_by_value_desc(kills)
        set by_key to sort_by_key(kills)
        set custom to sort_map_by(kills, function(name, n) return n)
        send "maps ${map_size(by_key)} ${map_size(custom)}" to sender

        loop by_val as name -> n {
            send "${name}: ${n}" to sender
        }
    }
}
