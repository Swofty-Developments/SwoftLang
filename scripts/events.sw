// Phase-7 generated event catalog showcase. Handlers can name ANY concrete
// Minestom event — by catalog short name ("EntityShoot") or simple class
// name ("PlayerFinishItemUseEvent") — not just the curated typed core.
// Catalog properties are Any-typed rows discovered from the event class
// (writable only where the class ships a matching setter), and
// 'cancel event' is legal exactly where the class is cancellable.
//
// Fishing has its own first-class typed events (PlayerCastRod, FishBite,
// PlayerCatchFish, PlayerReelIn — see scripts/fishing.sw); the generic
// coverage below sticks to the raw catalog side of that same territory:
// rod-style item use, projectile flight/collision, and item pickup.

// --- casting: starting to use the rod-like item ---
event PlayerBeginItemUse {
    priority: 2

    execute {
        send "casting ${event.item_stack} (${event.animation})" to event.player
        // item_use_duration has a setter in the catalog, so it is writable
        set event.item_use_duration to 30
    }
}

// reeling in: the simple-class spelling resolves through the catalog to
// the same canonical short name ("PlayerFinishItemUse")
event PlayerFinishItemUseEvent {
    execute {
        send "reeled in after ${event.use_duration} ticks" to event.player
    }
}

// --- the bobber in flight is just a projectile ---
event EntityShoot {
    execute {
        // power and spread are settable per the catalog's setter scan
        set event.power to 1.5
        set event.spread to 0.0
        send "line out: ${event.projectile} towards ${event.to}" to all
    }
}

event ProjectileCollideWithBlock {
    execute {
        send "splash! landed on ${event.block}" to all
        // collide events implement CancellableEvent, so this is legal
        cancel event
    }
}

event ProjectileCollideWithEntity {
    execute {
        send "snagged ${event.target}" to all
    }
}

// --- the catch: picking the drop back up ---
event PickupItem {
    priority: 1

    execute {
        if event.cancelled {
            send "too slow, the catch is gone" to all
        }
        send "caught ${event.item_stack}" to all
    }
}

// --- beyond fishing: any of the 87 catalog events just works ---
event EntityVelocity {
    execute {
        set event.velocity to velocity(0.0, 1.0, 0.0)
        cancel event
    }
}

// the class spelling of the ENGINE item-use event: the curated
// 'PlayerUseItem' identifier wraps the custom-items event (a different
// class), so this spelling reaches the genuine Minestom
// PlayerUseItemEvent — generated rows, settable item_use_time,
// cancellable (e.g. to cancel eating)
event PlayerUseItemEvent {
    execute {
        send "engine item use: ${event.item_stack}" to event.player
        set event.item_use_time to 100
    }
}
