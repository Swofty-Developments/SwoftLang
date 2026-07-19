gui "buttons" {
    rows: 1
    title: "Buttons"

    slot 4 {
        item { material: "DIAMOND", name: "<aqua>Click me" }
        on_click(right) {
            send "right click" to player
        }
        on_click(shift_left) {
            send "shift left click on slot ${slot}" to player
        }
        on_click {
            send "some other click: ${click_type}" to player
        }
    }
}
