gui "confirm" {
    rows: 1
    title: "<red>Are you sure?"

    slot 3 {
        item { material: "LIME_WOOL", name: "<green>Yes" }
        on_click {
            close gui for player
        }
    }
    slot 5 {
        item { material: "RED_WOOL", name: "<red>No" }
        on_click {
            go back for player
        }
    }
}

command "confirm" {
    execute {
        open gui "confirm" to sender
    }
}
