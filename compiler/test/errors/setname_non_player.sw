mob Z { type: "ZOMBIE" }
Player {
    on_join {
        spawn mob Z at player.location as m
        set name of m to "hi" for m
    }
}
