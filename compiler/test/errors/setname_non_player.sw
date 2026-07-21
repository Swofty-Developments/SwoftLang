mob "z" { type: "ZOMBIE" }
Player {
    on_join {
        spawn mob "z" at player.location as m
        set name of m to "hi" for m
    }
}
