Player {
    on_join() {
        set nametag of this to "<red>[ADMIN] ${this.name}"
        set nametag prefix of this to "&6[VIP] " for this
        set nametag color of this to red
        set nametag suffix of this to " &7(AFK)" for all
        reset nametag of this for all

        send packet "ParticlePacket" {
            particle: "minecraft:flame",
            overrideLimiter: false, longDistance: false,
            x: 100.5, y: 65.0, z: 20.5,
            offsetX: 0.5, offsetY: 0.5, offsetZ: 0.5,
            maxSpeed: 0.01, count: 40
        } to this

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

Packet {
    on "ClientPlayerActionPacket" {
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
