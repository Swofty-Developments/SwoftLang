mob Ghoul {
    type: "ZOMBIE"
    health: 40
}

struct Anchorwatch {
    @EventReceiver anchor: Mob

    anchor {
        on_death { broadcast "the anchor fell" }
    }
}

command "raid" {
    execute {
        spawn mob Ghoul at location(0, 64, 0) as g
        set watch to Anchorwatch { anchor: g }
    }
}
