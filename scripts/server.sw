server {
    auth: offline
    host: "0.0.0.0"
    port: 25565
    brand: "SwoftLang"
    motd: "<green>A SwoftLang server"
}

command "whereami" {
    description: "Confirm which server you are on"

    execute {
        send "<lime>You are on a SwoftLang-powered server" to sender
    }
}
