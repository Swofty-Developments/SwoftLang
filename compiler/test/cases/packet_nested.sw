// design 5D: nested record objects inside packet field LISTS (the
// PlayerInfoUpdatePacket entries/properties shape) and explicit 'none'
// for nullable packet components (displayName, chatSession)
event PlayerJoin {
    execute {
        send packet "PlayerInfoUpdatePacket" {
            actions: ["ADD_PLAYER", "UPDATE_LISTED"],
            entries: [{
                uuid: "a0000000-0000-4000-8000-000000000001",
                username: "Steve",
                properties: [{ name: "textures", value: "tex", signature: "sig" }],
                listed: true,
                latency: 0,
                gameMode: "SURVIVAL",
                displayName: none,
                chatSession: none,
                listOrder: 0
            }]
        } to event.player
    }
}
