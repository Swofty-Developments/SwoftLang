// on_right_click binds exactly one parameter (player: Player).
item "wand" {
    material: "STICK"
    on_right_click(player, extra) {
        send "hi" to player
    }
}
