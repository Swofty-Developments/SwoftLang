Player {
    on_join() {
        set nametag of this to "<red>[ADMIN] ${this.name}"
        set nametag prefix of this to "&6[VIP] "
        set nametag suffix of this to " &7(AFK)"
        set nametag color of this to red
    }
}
