// Phase 11 collections showcase: Integer-keyed maps, one-call leaderboard
// sorting over a map, chance-based loot drops, and a non-mutating shuffle.
// Everything here runs headless under the exec harness / --collections-test.

command "leaderboard" {
    execute {
        // an Integer-keyed map: player id -> kill count. The literal infers
        // map<Integer, Integer> from its integer keys.
        set kills to { 101: 12, 102: 30, 103: 7, 104: 21 }

        // record more kills with the 'set m at k to v' natural form. It takes
        // an Integer key because the map is Integer-keyed.
        set kills at 103 to 8
        set kills at 105 to 30

        // ONE call sorts the whole map into descending-by-value iteration
        // order -- this is the leaderboard. Ties keep prior order, so 102
        // ranks before 105 (both 30).
        set ranked to sort_by_value_desc(kills)

        send "leaderboard (${size of ranked} players):" to sender
        loop ranked as id -> score {
            send "player ${id}: ${score} kills" to sender
        }

        // top of the board without a full sort: max_by over the Integer keys,
        // scoring each by its value. kills[id] is optional<Integer>.
        set best to max_by(keys of kills, function(id) return kills[id] otherwise 0)
        send "leader is player ${best otherwise 0}" to sender
    }
}

command "loot" {
    execute {
        // a loot pool: shuffle returns a NEW list, leaving 'pool' untouched.
        set pool to ["sword", "shield", "potion", "gold", "gem"]
        set bag to shuffle(pool)

        send "rolling ${length(bag)} items:" to sender
        loop bag as item {
            // the "40% drop" primitive: random_chance clamps p into [0,1]
            if random_chance(0.4) {
                send "dropped ${item}" to sender
            }
        }

        // proof shuffle did not mutate the argument
        send "pool still has ${length(pool)} items" to sender

        // rarity weighting as an Integer-keyed table (tier -> weight), then a
        // one-call descending sort so the commonest tier iterates first.
        set weights to { 1: 60, 2: 30, 3: 9, 4: 1 }
        set by_weight to sort_by_value_desc(weights)
        loop keys of by_weight as tier {
            send "tier ${tier} weight ${by_weight[tier] otherwise 0}" to sender
        }

        // pick a random rarity tier by composing random_in with 'keys of'
        set rolled to random_in(keys of weights) otherwise 1
        send "rolled tier ${rolled}" to sender
    }
}
