npc "greeter" {
    location: location(5, 64, 5)
    name: "<green>Guide (${player.name})"
    skin: "Notch"
    on_click {
        send "<yellow>Welcome, ${player.name}!" to player
    }
}
