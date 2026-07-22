// §4.4: a statically-known custom value may not be assigned into a reactive
// base field (the Ghoul owns its behavior in its own block).
mob Ghoul {
    type: "ZOMBIE"
    health: 40
}

struct Arena {
    @EventReceiver anchor: Mob
}

command "x" {
    execute {
        spawn mob Ghoul at location(0, 100, 0) as boss
        set a to Arena { anchor: boss }
    }
}
