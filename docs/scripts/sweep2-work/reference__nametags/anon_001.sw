event PlayerJoin {
    execute {
        set nametag of event.player to "<red>[ADMIN] ${event.player.name}"
        set nametag prefix of event.player to "&6[VIP] "
        set nametag suffix of event.player to " &7(AFK)"
        set nametag color of event.player to red
    }
}
