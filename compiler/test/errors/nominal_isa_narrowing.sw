// a base Mob is NOT a Ghoul without narrowing: nominal subtyping is one-way
mob Ghoul {
    type: "ZOMBIE"
}
function empower(g: Ghoul) {
    set g.health to 100
}
Player {
    on_join {
        spawn mob by id "ghoul" at location(0, 100, 0) as dyn
        empower(dyn)
    }
}
