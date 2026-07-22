command "props" {
    execute {
        set sender.health to sender.max_health
        set sender.location.y to sender.location.y + 10   // wither + one teleport
        set sender.held_item.amount to 32
        set sender.gamemode to "creative"                 // enum-validated string
    }
}
