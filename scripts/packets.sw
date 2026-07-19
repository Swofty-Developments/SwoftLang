// Phase-5 per-viewer nametags + raw packet escape hatch (designs 5C/5D).
// Nametags ride TeamsPacket per viewer; send packet constructs the real
// pinned-Minestom record via its canonical constructor (field names must
// match the record components — ParticlePacket's count field is
// 'particleCount'); on packet hooks inbound client packets with real
// cancel support (PlayerPacketEvent path).

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
            maxSpeed: 0.01, particleCount: 40
        } to event.player

        send packet "TeamsPacket" {
            teamName: "nt_lobby",
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
            send "<red>No mining in the lobby." to player
            cancel packet
        }
    }
}
