// W-events: typed engine events reached through OOP receiver methods. Each
// method binds `this` to the receiver instance and its user binders to the
// event's typed args; settable args are writable, `cancel event` is legal only
// inside a cancellable method.

Entity {
    // EntityDamage -> Entity.on_hit: `this` is the victim, `attacker` the source.
    on_hit(attacker) {
        if attacker exists {
            send "attacker: ${attacker}" to all
        }
    }

    // EntityAttack -> Entity.on_attack: `this` is the attacker, `target` the victim.
    on_attack(target) {
        send "${this} hit ${target}" to all
    }
}

Player {
    on_move(new_position) {
        set new_position to this.location
    }

    on_death(death_text, chat_message) {
        set death_text to "<red>${this.name} was slain"
    }

    on_gamemode_change(new_game_mode) {
        send "${this.name} -> ${new_game_mode}" to this
    }

    on_use_item(item, hand) {
        send "using ${item} in ${hand}" to this
        cancel event
    }

    on_interact_block(block, location, face, hand) {
        send "clicked ${block} face ${face} at ${location.block_y}" to this
    }
}
