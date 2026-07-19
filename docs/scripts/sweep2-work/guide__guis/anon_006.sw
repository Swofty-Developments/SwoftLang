gui "rename" {
    rows: 1
    title: "Rename"

    slot 4 {
        item { material: "NAME_TAG", name: "<yellow>Rename" }
        on_click {
            async {
                set answer to prompt_input(player, "new name?")
                send "renamed to: ${answer}" to player
            }
            close gui for player
        }
    }
}
