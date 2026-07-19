event PlayerJoin {
    execute {
        set nametag of event.player to "<red>[ADMIN] ${event.player.name}"
        set nametag prefix of event.player to "&6[VIP] " for event.player
        set nametag color of event.player to red
        set nametag suffix of event.player to " &7(AFK)" for all
        reset nametag of event.player for all

        send packet "ParticlePacket" {
            particle: "minecraft:flame",
            overrideLimiter: false, longDistance: false,
            x: 100.5, y: 65.0, z: 20.5,
            offsetX: 0.5, offsetY: 0.5, offsetZ: 0.5,
            maxSpeed: 0.01, count: 40
        } to event.player

        send packet "TeamsPacket" {
            teamName: "nt_test",
            action: {
                type: "CreateTeamAction",
                displayName: "",
                friendlyFlags: 1,
                nameTagVisibility: "ALWAYS",
                collisionRule: "ALWAYS",
                teamColor: "gold",
                teamPrefix: "&6[MVP] ",
                teamSuffix: "",
                entities: ["Swofty"]
            }
        } to all
    }
}

on packet "ClientPlayerDiggingPacket" {
    execute {
        if packet.status is "STARTED_DIGGING" {
            send "<red>No mining here." to player
            cancel packet
        }
        async {
            wait 5 ticks
            send "<gray>(delayed) dig detected" to player
        }
    }
}
