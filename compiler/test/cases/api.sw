// phase-6 http api: server{} http{}, api decls, request.*, reply

server {
    port: 25566
    http { port: 8090, bind: "127.0.0.1" }
}

api "/status" {
    execute {
        reply with "ok ${server.tps}"
    }
}

api "/give/:player" {
    method: POST
    execute async {
        set target to player(request.params.player)
        if target exists {
            send "<green>You got a gift from the web!" to target
            reply code 200 with "delivered to ${request.params.player}"
        } else {
            reply code 404 with "no such player: ${request.params.player}"
        }
    }
}

api "/motd" {
    method: PUT
    execute {
        set server motd to request.body
        reply with "motd is now ${request.body} (method ${request.method} path ${request.path} query ${request.query})"
    }
}
