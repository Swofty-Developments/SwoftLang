server {
    auth: mojang
    host: "0.0.0.0"
    port: 25565
    brand: "SwoftLang"
    motd: "<green>A SwoftLang server"
    favicon: "server-icon.png"

    http {
        port: 8080
        bind: "127.0.0.1"
    }

    permissions {
        "Swofty": ["myserver.admin"]
    }
}

Server {
    on_list_ping(status) {
        set status to "<green>${length(all_players())} adventurers online"
    }
}

every 300 seconds {
    broadcast "<gray>Remember to vote! <yellow>/vote"
}

api "/health" {
    method: GET
    execute async {
        reply with "ok, ${length(all_players())} online"
    }
}
