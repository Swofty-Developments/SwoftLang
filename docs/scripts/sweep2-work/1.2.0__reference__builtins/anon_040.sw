command "loot" {
    execute {
        set f to random_float(0.0, 1.0)
        send "roll ${f}" to sender

        if random_chance(0.1) {           // true 10% of the time — the "drop chance" primitive
            send "<gold>rare drop!" to sender
        }

        if random_bool() {
            send "heads" to sender
        }

        set drops to ["sword", "shield", "potion"]
        set pick to random_in(drops) otherwise "nothing"
        send "you get ${pick}" to sender

        loop shuffle(drops) as d {        // shuffle returns a new list; 'drops' is untouched
            send "${d}" to sender
        }
    }
}
