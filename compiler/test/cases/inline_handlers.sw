// First-class inline event handlers (W-inline-handlers): on_<event>(binders)
// { body } inside item/mob/hologram declarations. Handler names are validated
// against each kind's fixed table; the binders bind positionally to the fixed
// types, `this` binds to the declaration's instance, and the body is
// sync-colored. Emitted under the additive "handlers" map.

// An item ("this" = the ItemStack) with the big new handler set, including a
// multi-arg block handler and a brace-free one-liner.
item "magic_wand" {
    material: "BLAZE_ROD"
    name: "<gold>Magic Wand"

    on_right_click(player) {
        send "<aqua>Zap!" to player
    }

    on_right_click_block(player, loc, face) {
        send "<gray>Struck ${face} at ${loc.block_x}, ${loc.block_y}, ${loc.block_z}" to player
    }

    on_attack_entity(player, target) {
        send "<red>You struck a ${target.type}!" to player
    }

    on_left_click(player) send "<yellow>Swish" to player
}

// A mob ("this" = the Mob) mixing an already-shipped dedicated handler
// (on_death, top-level JSON) with the new generic ones (on_click / on_target /
// on_tick, under "handlers").
mob "boss" {
    type: "WITHER"
    name: "<dark_red>The Boss"
    health: 300

    on_death {
        broadcast "<gold>The boss has fallen!"
    }

    on_click(player) {
        send "<gray>You poke ${this.custom_id}." to player
    }

    on_target(target) {
        if target exists {
            broadcast "<red>The boss sets its sights on a ${target.type}!"
        }
    }

    on_tick() set this.glowing to true
}

// A hologram ("this" = the text-display) with whole-click and per-line click.
hologram "shop" {
    location: location(0, 65, 0)
    lines {
        line "<gold><bold>Shop"
        line "<gray>Click a line"
    }

    on_click(player) send "<green>Welcome, ${player.name}!" to player

    on_line_click(player, line) {
        send "<gray>You clicked line ${line}" to player
    }
}
