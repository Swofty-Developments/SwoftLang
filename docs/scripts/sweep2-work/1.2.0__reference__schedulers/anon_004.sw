every 1 seconds as "heartbeat" {
    if run >= 5 stop
    broadcast "heartbeat"
}

command "flash" {
    execute {
        // fixed-count repeat, spaced by 'every', with the run counter in scope
        repeat 3 times every 10 ticks {
            if run > 1 send "again" to sender
            send "flash" to sender
        }

        // a named handle that self-cancels at run 10
        set h to schedule every 1 seconds as "counter" {
            if run >= 10 stop
        }

        // liveness by handle or by name
        if is_running(h) send "counter is running" to sender
        if is_running("heartbeat") send "heartbeat is running" to sender

        // cancel by name and by handle
        cancel schedule "counter"
        cancel schedule h
    }
}
