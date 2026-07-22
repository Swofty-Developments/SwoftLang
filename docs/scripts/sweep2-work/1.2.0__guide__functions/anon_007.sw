command "later" {
    execute {
        set task to async function(msg: String) {
            wait 1 seconds
            send "later: ${msg}" to sender
        }
        spawn task("hello")
        send "wait for it" to sender
    }
}
