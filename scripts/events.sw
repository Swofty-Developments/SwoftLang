// Typed engine events reached through OOP receiver methods. Each method binds
// the receiver instance under its natural noun and the event's typed args as
// bare variables; settable args are writable, and `cancel event` is legal only
// inside a cancellable method.
//
// Fishing has its own first-class typed events (PlayerCastRod, FishBite,
// PlayerCatchFish, PlayerReelIn — see scripts/fishing.sw); the coverage below
// sticks to the projectile/velocity/item-use territory around it.

Entity {
    // --- the bobber in flight is just a projectile being shot ---
    on_shoot {
        // power and spread are settable per the catalog's setter scan
        set power to 1.5
        set spread to 0.0
        send "line out: ${projectile} towards ${to}" to all
    }

    // any live entity's velocity can be vetoed / rewritten
    on_velocity {
        set velocity to velocity(0.0, 1.0, 0.0)
        cancel event
    }
}

Projectile {
    on_hit_block {
        send "splash! landed on ${block}" to all
        // collide events are cancellable
        cancel event
    }

    on_hit_entity {
        send "snagged ${target}" to all
    }
}

Item {
    // --- the catch: picking the drop back up ---
    on_pickup {
        send "caught the drop for ${player.name}" to all
    }
}

Player {
    // --- casting: starting to use the rod-like item ---
    on_begin_item_use {
        send "casting..." to player
    }

    // reeling in
    on_finish_item_use {
        send "reeled in" to player
    }

    // the engine's own PlayerUseItemEvent, reached through on_use_item
    on_use_item {
        send "engine item use: ${item} in ${hand}" to player
        cancel event
    }
}
