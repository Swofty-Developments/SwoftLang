mob "z" { type: "ZOMBIE" }
Player {
    on_join() {
        spawn mob "z" at this.location as m
        set name of m to "hi" for m
    }
}
