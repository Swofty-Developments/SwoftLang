// Phase-9 dispenser runtime: 'dispense from <location>' fires the dispenser or
// dropper block at a location, emitting the cancellable BlockDispense event
// (location, block, item rw, direction, cancelled).

command "fire" {
    execute {
        dispense from location(10, 64, 20)
        dispense from sender.location
    }
}

Block {
    on_dispense {
        // inspect what comes out, then veto the vanilla dispense
        broadcast "dispensed ${item.name} facing ${direction}"
        cancel event
    }
}
