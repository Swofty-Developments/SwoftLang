// Receiver methods that ride the generated engine event catalog: the receiver
// instance binds under its natural noun and the event's typed args bind as bare
// variables, with catalog-driven writability (set the rw args) and
// cancellability (cancel event only inside a cancellable method).

Entity {
    on_pickup_item {
        send "picked up ${item_stack}" to all
        cancel event
    }

    on_shoot {
        set power to 2.0
        set spread to 0.0
        send "projectile ${projectile} towards ${to}" to all
    }
}

Player {
    on_begin_item_use {
        cancel event
    }

    on_join {
        send "spawned for ${player.name}" to all
    }
}
