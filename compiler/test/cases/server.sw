server {
    auth: velocity "super-secret"
    host: "0.0.0.0"
    port: 25577
    brand: "SwoftLang"
    motd: "<green>SwoftLang test server"
}

command "whereami" {
    execute {
        send "You are on the SwoftLang server" to sender
    }
}
