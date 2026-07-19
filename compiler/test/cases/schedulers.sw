// phase-6 schedulers: top-level 'every' decls + schedule exprs + cancel

every 60 seconds {
    broadcast "Server heartbeat"
    if server.tps < 15.0 broadcast "<red>Server is lagging!"
}

every 10 ticks broadcast "fast tick group"

command "remind" {
    execute {
        set handle to schedule after 5 seconds {
            send "5 seconds passed" to sender
        }
        set repeating to schedule after 1 seconds every 2 seconds {
            send "tick" to sender
        }
        set immediate to schedule {
            send "ran once on the async runtime" to sender
        }
        cancel schedule handle
        cancel schedule repeating
        cancel schedule immediate
    }
}
