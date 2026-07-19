gui "ranges" {
    rows: 6
    title: "Ranges"

    slots [10..16, 19..25] {
        item { material: "PAPER", name: "<white>tile" }
    }

    editable [28..43] {
        on_change {
            send "slot ${slot} changed" to player
        }
    }
}
