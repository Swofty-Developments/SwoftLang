// Phase-3 persistence showcase: a files backend with write-behind flushing,
// global counters that survive restarts, and a per-player keyed counter.

storage {
    backend: files "data/swoftlang"
    flush: every 10 seconds
}

persistent runs: Integer = 0
persistent karma: Double = 0.0
persistent last_runner: String = "nobody"
persistent has_run_before: Boolean = false
persistent visits for Player: Integer = 0

command "persist" {
    description: "Increment and show the persistent counters"

    execute {
        set runs to runs + 1
        set karma to karma + 0.5
        set visits for sender to visits for sender + 1

        send "Run #${runs} (karma ${karma}), seen before: ${has_run_before}" to sender
        send "Last runner was ${last_runner}, your visits: ${visits for sender}" to sender

        set last_runner to "harness"
        set has_run_before to true
    }
}
