mob "boss_wither" {
    type: "WITHER"
    health: 600
}

every 30 seconds {
    broadcast "<gray>Autosave in 10 seconds..."
}

every 5 ticks {
    loop all_mobs("boss_wither") as boss {
        set boss.name to "<dark_red>Wither <red>${boss.health}❤"
    }
}
