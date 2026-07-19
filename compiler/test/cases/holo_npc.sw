// First-class hologram + npc constructs (GROUP C/D).

// A per-viewer hologram: a line interpolates ${player.name}, so the emitter
// marks per_viewer = true and re-renders the stack per viewer.
hologram "spawn_info" {
    location: location(0, 65, 0)
    billboard: center
    scale: 1.5
    update: every 1 seconds
    lines {
        line "<gold><bold>Welcome!"
        blank
        line "<gray>Hi ${player.name}"
        if player.health > 10 {
            line "<green>Healthy"
        } else {
            line "<red>Careful"
        }
        loop 2 times {
            line "<yellow>* star *"
        }
    }
}

// A static (all-viewers) hologram: no player-scoped path, per_viewer = false.
hologram "rules" {
    location: location(4, 70, 4)
    billboard: fixed
    lines {
        line "<aqua>Server Rules"
        line "<gray>1. Be nice"
    }
}

// An npc with a fetched username skin, per-viewer name, look tracking, and both
// click handlers.
npc "guide" {
    location: location(5, 64, 5)
    name: "<green>Village Guide (${player.name})"
    skin: "Notch"
    look_at_players: true
    on_click(player) {
        send "<yellow>Hello ${player.name}!" to player
    }
    on_left_click(clicker) {
        send "<red>Don't hit me!" to clicker
    }
}

// An npc with a direct texture skin.
npc "villager" {
    location: location(8, 64, 8)
    skin: skin("ewogICJ0ZXh0dXJlcyI=", "sig-bytes-here")
}

command "holo" {
    execute {
        show hologram "spawn_info" to sender
        show hologram "rules" to all
        hide hologram "spawn_info" from sender
        set hologram "spawn_info" line 2 to "<green>updated line"
        move hologram "spawn_info" to location(1, 66, 1)
        remove hologram "rules"

        set npc "guide" skin "Herobrine"
        set npc "guide" name "<red>Renamed Guide"
        set npc "guide" location location(6, 64, 6)
        set npc "villager" skin skin("newtexture", "newsig")
        remove npc "villager"
    }
}
