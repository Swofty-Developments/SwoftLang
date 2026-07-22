gui "menu" {
    rows: 3
    title: "Server Menu"

    slot 13 {
        item { material: "COMPASS", name: "<aqua>Warp home" }
        on_click {
            send "<gray>Warping..." to player
            close gui for player
        }
    }
}

command "menu" {
    execute {
        open gui "menu" to sender
    }
}
