// Phase-7 generated event catalog: any Minestom event by short name or
// simple class name, Any-typed property access with catalog writability,
// and catalog-driven cancellability. The pinned Minestom snapshot ships no
// fishing events (FISHING_BOBBER is entity-only), so the closest engine
// coverage exercised here is item pickup/consumption.

event PickupItem {
    execute {
        send "picked up ${event.item_stack}" to all
        if event.cancelled {
            send "already cancelled" to all
        }
        cancel event
    }
}

// simple-class spelling resolves through the catalog (emits "PlayerBeginItemUse")
event PlayerBeginItemUseEvent {
    priority: 3

    execute {
        set event.item_use_duration to 10
        cancel event
    }
}

event EntityShoot {
    execute {
        set event.power to 2.0
        set event.spread to 0.0
        send "projectile ${event.projectile} towards ${event.to}" to all
    }
}

// A0.1 reverse index: the catalog name 'PlayerSpawn' now collapses to the
// typed PlayerJoin rows (its class is wrapped by the curated PlayerJoin), so
// first_spawn is a typed Boolean and player a typed Player, and the handler
// emits the curated identifier "PlayerJoin".
event PlayerSpawn {
    execute {
        send "spawned (first: ${event.first_spawn}) for ${event.player.name}" to all
    }
}
