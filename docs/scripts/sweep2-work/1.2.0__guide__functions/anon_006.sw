command "counter" {
    execute {
        set count to 0
        set inc to function() set count to count + 1
        inc()
        inc()
        send "count = ${count}" to sender     // 2 — the lambda mutates the shared variable
    }
}
