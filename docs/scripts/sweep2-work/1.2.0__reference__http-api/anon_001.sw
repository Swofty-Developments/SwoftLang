server {
    http {
        port: 8080
        bind: "127.0.0.1"
    }
}

api "/status" {
    method: GET
    execute {
        reply with "online=${length(all_players())} tps=${server.tps}"
    }
}
