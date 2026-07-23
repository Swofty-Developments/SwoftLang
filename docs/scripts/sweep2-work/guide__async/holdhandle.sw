async function slow_lookup(id: Integer) {
    wait 500 millis
    return id * 10
}

async function process(p: Player, id: Integer) {
    set pending to spawn slow_lookup(id)   // starts the clock now
    send "<gray>crunching..." to p         // this runs while the lookup is in flight
    wait 100 millis                         // ...and so does this
    set value to await pending             // by now it's very likely already done
    send "<lime>result ${value}" to p
}
