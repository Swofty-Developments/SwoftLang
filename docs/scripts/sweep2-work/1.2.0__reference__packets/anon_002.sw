command "ghost" {
    execute {
        send packet "PlayerInfoUpdatePacket" {
            actions: ["ADD_PLAYER", "UPDATE_LISTED"],
            entries: [{
                uuid: "a0000000-0000-4000-8000-000000770000",
                username: "Ghost",
                properties: [],
                listed: true,
                latency: 0,
                gameMode: "SURVIVAL",
                displayName: none,
                chatSession: none,
                listOrder: 0
            }]
        } to sender
        send packet "SpawnEntityPacket" {
            entityId: 770000,
            uuid: "a0000000-0000-4000-8000-000000770000",
            type: 147,
            position: sender.location,
            headRot: 0.0,
            data: 0,
            velocityX: 0, velocityY: 0, velocityZ: 0
        } to sender
    }
}
