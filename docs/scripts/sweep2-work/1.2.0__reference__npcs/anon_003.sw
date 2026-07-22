npc "greeter" {
    location: location(5, 64, 5)
    name: "<green>Guide (${player.name})"
    skin: "Notch"
    on_click(clicker) {
        send "<yellow>Welcome, ${clicker.name}!" to clicker
    }
}
