server {
    http {
        port: 8080
        bind: "127.0.0.1"
    }
}

api "/stats/:name" {
    method: GET
    execute async {
        set p to player(request.params.name)
        if p exists {
            reply with "online, ping ${p.latency}ms"
        } else {
            reply code 404 with "offline"
        }
    }
}
