async function fetch_score(base: Integer) {
    wait 50 millis
    return base * 2
}

async function farewell(name: String) {
    wait 80 millis
    send "goodbye, ${name}"
}

command "burst" {
    description: "Sync entry point that fires an async block"

    execute {
        send "sync: before async block"
        async {
            wait 60 millis
            send "async block: finished after 60ms"
        }
        send "sync: after async block (no waiting here)"
    }
}

command "asyncdemo" {
    description: "Async command handler with waits, spawn and async return values"

    execute async {
        wait 40 millis
        send "task: starting"
        set doubled to fetch_score(21)
        send "task: fetch_score(21) = ${doubled}"
        wait 2 ticks
        send "task: tick wait done"
        spawn farewell("swofty")
        send "task: farewell spawned"
        set total to fetch_score(doubled) + 16
        send "task: total = ${total}"
    }
}
