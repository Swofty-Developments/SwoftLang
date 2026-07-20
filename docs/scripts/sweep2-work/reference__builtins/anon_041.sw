command "seeded" {
    execute {
        random_seed(1337)                    // reproducible sequence from here
        set roll to random_int(1, 20)
        set weight to random_double(0.0, 1.0)
        if chance(0.25) {
            send "<gold>rare!" to sender
        }
        set drops to ["sword", "shield", "potion"]
        set pick to random_element(drops) otherwise "nothing"
        send "roll ${roll} weight ${weight} pick ${pick} id ${random_uuid()}" to sender
    }
}
