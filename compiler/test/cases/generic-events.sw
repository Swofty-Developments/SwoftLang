// Receiver methods that ride the generated engine event catalog: `this` binds
// to the receiver instance and the user binders to the event's typed args, with
// catalog-driven writability (set the rw args) and cancellability (cancel event
// only inside a cancellable method).

Entity {
    on_pickup_item(item_stack, item_entity) {
        send "picked up ${item_stack}" to all
        cancel event
    }

    on_shoot(projectile, dest, power, spread) {
        set power to 2.0
        set spread to 0.0
        send "projectile ${projectile} towards ${dest}" to all
    }
}

Player {
    on_begin_item_use() {
        cancel event
    }

    on_join() {
        send "spawned for ${this.name}" to all
    }
}
