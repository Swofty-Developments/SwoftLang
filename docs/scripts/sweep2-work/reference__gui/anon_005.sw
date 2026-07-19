gui "chest" {
    rows: 3
    title: "Deposit"

    editable [9..17] {
        on_change {
            send "slot ${slot}: ${old_item.material} -> ${new_item.material}" to player
        }
    }
}
