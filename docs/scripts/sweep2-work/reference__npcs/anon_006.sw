npc "sentry" {
    location: location(0, 64, 0)
    name: "<gold>Sentry (${player.name})"
    skin: "Notch"
    viewable: false
    on_click(player) {
        send "<yellow>Halt, ${player.name}!" to player
    }
    on_tick() {
        set this.glowing to true
    }
}
