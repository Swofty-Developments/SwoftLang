// Phase 10: the last doc-banner gaps — entity poses, world weather, the
// PlayerCommand veto event, and item <-> NBT string round-tripping.

// PlayerCommand fires before a command is dispatched; it is cancellable and
// 'command' is rw so a handler can rewrite or veto what runs.
Player {
    on_command {
        if command contains "stop" {
            send "that command is blocked" to player
            cancel event
        }
        // normalise the command before it dispatches
        set command to lowercase(command)
    }
}

command "gaps" {
    execute {
        // entity pose (EntityPose enum) + the sneaking convenience boolean
        spawn entity "ARMOR_STAND" at location(0, 64, 0) as stand
        set stand.pose to "sneaking"
        set stand.sneaking to true

        // world weather: a writable clear|rain|thunder enum, plus read-only
        // raining/thundering booleans
        set w to sender.world
        set w.weather to "thunder"
        if w.raining {
            send "it is raining" to sender
        }

        // item <-> NBT string: serialize a stack, then parse it back (the parse
        // is optional — malformed input yields none)
        set snapshot to to_nbt(sender.held_item)
        set restored to from_nbt(snapshot)
        if restored exists {
            send "restored an item from nbt" to sender
        }
    }
}
