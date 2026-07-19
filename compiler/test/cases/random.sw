// Phase 11: random builtins. random() (inclusive ints) stays; these add float,
// chance, fair coin, random element, and a non-mutating shuffle.

command "random" {
    execute {
        set f to random_float(0.0, 1.0)
        send "f ${f}" to sender

        // the "10% drop" primitive
        if random_chance(0.1) {
            send "lucky" to sender
        }

        if random_bool() {
            send "heads" to sender
        }

        // random element of a list is optional<T> (none when empty)
        set loot to ["sword", "shield", "potion"]
        set drop to random_in(loot) otherwise "nothing"
        send "drop ${drop}" to sender

        // shuffle returns a new list, leaving the argument untouched
        set shuffled to shuffle(loot)
        loop shuffled as item {
            send "${item}" to sender
        }

        // compose random_in with map_keys to pick a random key
        set weights to { "common": 1, "rare": 5 }
        set pick to random_in(map_keys(weights)) otherwise "?"
        send "pick ${pick}" to sender
    }
}
