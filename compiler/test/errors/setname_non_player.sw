mob "z" { type: "ZOMBIE" }
on PlayerJoin {
    spawn mob "z" at event.player.location as m
    set name of m to "hi" for m
}
