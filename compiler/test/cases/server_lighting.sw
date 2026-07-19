// server{} lighting: Boolean (default true). Disabling it emits an additive key.

server {
    auth: offline
    motd: "<green>No lighting"
    lighting: false
}

command "ping" {
    execute {
        send "pong" to sender
    }
}
