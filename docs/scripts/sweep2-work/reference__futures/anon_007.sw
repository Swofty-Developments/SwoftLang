async function slow_lookup(id: Integer) {
    wait 500 millis
    return id * 10
}

async function report(p: Player, pending: Future<Integer>) {
    send "working..." to p
    set value to await pending           // finish work started elsewhere
    send "result ${value}" to p
}

async function process(p: Player, id: Integer) {
    set handle to spawn slow_lookup(id)  // starts now
    report(p, handle)                    // hand the handle off
}
