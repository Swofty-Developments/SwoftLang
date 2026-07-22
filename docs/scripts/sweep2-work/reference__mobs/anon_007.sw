mob Elite {
    type: "ZOMBIE"
    health: 40
}

command "promote" {
    execute {
        spawn mob Elite at location(0, 64, 0) as g
        set g.tags.level to 5                    // store
        set lvl to g.tags.level otherwise 0      // read with a fallback
        send "level ${lvl}" to sender
        set g.tags.level to none                 // delete
    }
}
