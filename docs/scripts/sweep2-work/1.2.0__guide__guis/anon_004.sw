gui "vault" {
    rows: 6
    title: "Vault"

    fill: item("BLACK_STAINED_GLASS_PANE", name: " ")
    border: item("GRAY_STAINED_GLASS_PANE", name: " ")

    slots [10..16, 19..25] {
        item { material: "CHEST", name: "<gray>a storage slot" }
        on_click {
            send "slot ${slot}" to player
        }
    }

    editable [28..43] {
        on_change {
            send "slot ${slot} changed" to player
        }
    }
}
