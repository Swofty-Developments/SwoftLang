command "bad" {
    execute {
        set task to async function() wait 1 ticks
        task()
    }
}
