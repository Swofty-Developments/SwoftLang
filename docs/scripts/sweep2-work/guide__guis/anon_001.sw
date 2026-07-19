gui "shop" {
    rows: 3
    title: "<dark_green>Shop"

    slot 11 {
        item { material: "DIAMOND_SWORD", name: "<aqua>Sword <gray>(100 coins)" }
        on_click {
            send "<green>Purchased!" to player
            close gui for player
        }
    }
    slot 15 {
        item { material: "GOLDEN_APPLE", name: "<gold>Apple <gray>(20 coins)" }
        on_click {
            send "<green>Crunchy." to player
        }
    }
}

command "shop" {
    execute {
        open gui "shop" to sender
    }
}
