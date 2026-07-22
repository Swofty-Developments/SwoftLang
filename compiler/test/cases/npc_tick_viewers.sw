// W-viewers §2 + on_tick (per-viewer NPCs, like mobs/holograms).

// A fully per-viewer npc: viewable:false hides the fake player from everyone
// until it is explicitly shown, and on_tick fires every tick with `this`
// bound to the npc's fake-player entity.
npc "sentry" {
    location: location(0, 64, 0)
    name: "<gold>Sentry (${player.name})"
    skin: "Notch"
    viewable: false
    on_click {
        send "<yellow>Halt, ${player.name}!" to player
    }
    on_tick {
        set npc.glowing to true
    }
}

// A hologram with a per-tick handler; `hologram` binds to its text-display stack.
hologram "clock" {
    location: location(0, 66, 0)
    lines {
        line "<aqua>Clock"
    }
    on_tick {
        set hologram.text to "<aqua>Clock"
    }
}

command "sentry" {
    execute {
        // name-keyed viewer control, routed through the same Viewable machinery
        show npc "sentry" to sender
        show npc "sentry" to all
        hide npc "sentry" from sender

        // viewers of npc "n" reads the fake player's getViewers -> List<Player>
        loop viewers of npc "sentry" as p {
            send "<gray>You can see the sentry." to p
        }
    }
}
