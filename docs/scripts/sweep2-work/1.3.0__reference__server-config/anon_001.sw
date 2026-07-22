server {
    auth: offline
    host: "0.0.0.0"
    port: 25565
    brand: "SwoftLang"
    motd: "<green>A SwoftLang server"
    favicon: "server-icon.png"
    open_to_lan: false

    http {
        port: 8080
        bind: "127.0.0.1"
    }

    permissions {
        "Swofty": ["swoftlang.admin", "swoftlang.teleport"]
        "Notch": ["swoftlang.teleport"]
    }
}
