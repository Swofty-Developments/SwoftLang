npc "guide" {
    location: location(5, 64, 5)
    name: "<green>Village Guide"
    skin: "Notch"
    look_at_players: true
    on_click(player) {
        send "<yellow>Hello ${player.name}!" to player
    }
}
