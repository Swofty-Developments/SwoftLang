Player {
    on_join {
        set nametag of player to "<red>[ADMIN] ${player.name}"
        set nametag prefix of player to "&6[VIP] "
        set nametag suffix of player to " &7(AFK)"
        set nametag color of player to red
    }
}
