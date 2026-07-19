// W-events: typed engine event catalog (design A1/A2). Every event.<prop>
// below typechecks to a real type; settable props are writable, others are
// read-only; 'cancel event' is legal only on cancellable events.

// EntityDamage — the highest-value typed event. Attack-veto goes through here
// (EntityAttackEvent is not cancellable): read the victim, scale the damage,
// inspect the source, veto lethal hits.
event EntityDamage {
    execute {
        set event.damage to event.damage * 2.0
        send "${event.entity} took ${event.damage} (${event.damage_type})" to all
        if event.attacker exists {
            send "attacker: ${event.attacker}" to all
        }
        if event.damage > 100.0 {
            cancel event
        }
    }
}

event PlayerMove {
    execute {
        if event.on_ground {
            set event.new_position to event.player.location
        }
    }
}

event PlayerDeath {
    execute {
        set event.death_text to "<red>${event.player.name} was slain"
        send "died in ${event.world}" to all
    }
}

event PlayerGameModeChange {
    execute {
        send "${event.player.name} -> ${event.new_game_mode}" to event.player
    }
}

event EntityAttack {
    execute {
        send "${event.entity} hit ${event.target}" to all
    }
}

event VanillaUseItem {
    execute {
        set event.item_use_time to 100
        send "using ${event.item_stack} in ${event.hand}" to event.player
        cancel event
    }
}

event PlayerBlockInteract {
    execute {
        send "clicked ${event.block} face ${event.block_face} at ${event.location.block_y}" to event.player
    }
}
