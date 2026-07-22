gui "search" {
    rows: 1
    title: "Search"

    slot 4 {
        item { material: "OAK_SIGN", name: "<yellow>Search..." }
        on_click {
            async {
                set query to prompt_input(player, "search for?")
                send "you searched: ${query}" to player
            }
            close gui for player
        }
    }
}
