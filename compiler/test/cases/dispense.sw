// Phase-9 dispenser runtime: 'dispense from <location>' fires the dispenser or
// dropper block at a location, emitting the cancellable BlockDispense event
// (location, block, item rw, direction, cancelled).

command "fire" {
    execute {
        dispense from location(10, 64, 20)
        dispense from sender.location
    }
}

event BlockDispense {
    execute {
        set facing to direction
        // droppers never launch projectiles: cancel and handle manually
        if block is "minecraft:dropper" {
            cancel event
        }
        // swap or inspect what comes out
        if event.item exists {
            broadcast "dispensed ${event.item.name} at ${location.block_x}, ${location.block_z}"
        }
        set event.item to item("ARROW")
    }
}
