// W-events: typed engine events reached through OOP receiver methods. Each
// method binds the receiver instance under its natural noun and the event's
// typed args as bare variables; settable args are writable, `cancel event` is
// legal only inside a cancellable method.

Entity {
    // EntityDamage -> Entity.on_hit: `entity` is the victim, `attacker` the source.
    on_hit {
        if attacker exists {
            send "attacker: ${attacker}" to all
        }
    }

    // EntityAttack -> Entity.on_attack: `entity` is the attacker, `target` the victim.
    on_attack {
        send "${entity} hit ${target}" to all
    }
}

Player {
    on_move {
        set new_position to player.location
    }

    on_death {
        set death_text to "<red>${player.name} was slain"
    }

    on_gamemode_change {
        send "${player.name} -> ${new_game_mode}" to player
    }

    on_use_item {
        send "using ${item} in ${hand}" to player
        cancel event
    }

    on_interact_block {
        send "clicked ${block} face ${face} at ${location.block_y}" to player
    }
}
