async function countdown(target: Player, from: Integer) {
    loop from times as i {
        send "<yellow>${from - i + 1}..." to target
        wait 1 seconds
    }
    send "<lime>Go!" to target
}

async function double_it(x: Integer) {
    wait 1 ticks
    return x * 2
}

command "start" {
    execute {
        spawn countdown(sender, 3)      // fire-and-forget from sync code
        async {                          // anonymous fire-and-forget block
            wait 10 ticks
            send "ready" to sender
        }
        send "started" to sender         // runs immediately, no blocking
    }
}

command "race" {
    execute async {                      // whole handler is async
        wait 5 ticks
        set doubled to double_it(21)     // direct async call: sequential
        send "result ${doubled}" to sender
    }
}
