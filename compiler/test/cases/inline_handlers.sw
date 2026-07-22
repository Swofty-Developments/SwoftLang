// First-class inline event handlers (W-inline-handlers): on_<event> { body }
// inside item/mob/hologram declarations. Handler names are validated against
// each kind's fixed table; the receiver instance binds under its natural noun
// and the event's args bind as bare variables, and the body is sync-colored.
// Emitted under the additive "handlers" map.

// An item ("item" = the ItemStack) with the big new handler set, including a
// multi-arg block handler and a brace-free one-liner.
item MagicWand {
    material: "BLAZE_ROD"
    name: "<gold>Magic Wand"

    on_right_click {
        send "<aqua>Zap!" to player
    }

    on_right_click_block {
        send "<gray>Struck ${face} at ${location.block_x}, ${location.block_y}, ${location.block_z}" to player
    }

    on_attack_entity {
        send "<red>You struck a ${target.type}!" to player
    }

    on_left_click send "<yellow>Swish" to player
}

// A mob ("mob" = the Mob) mixing an already-shipped dedicated handler
// (on_death, top-level JSON) with the new generic ones (on_click / on_target /
// on_tick, under "handlers").
mob Boss {
    type: "WITHER"
    name: "<dark_red>The Boss"
    health: 300

    on_death {
        broadcast "<gold>The boss has fallen!"
    }

    on_click {
        send "<gray>You poke ${mob.custom_id}." to player
    }

    on_target {
        if target exists {
            broadcast "<red>The boss sets its sights on a ${target.type}!"
        }
    }

    on_tick set mob.glowing to true
}

// A hologram ("hologram" = the text-display) with whole-click and per-line click.
hologram "shop" {
    location: location(0, 65, 0)
    lines {
        line "<gold><bold>Shop"
        line "<gray>Click a line"
    }

    on_click send "<green>Welcome, ${player.name}!" to player

    on_line_click {
        send "<gray>You clicked line ${line}" to player
    }
}
