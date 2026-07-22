item CarePackage {
    material: "CHEST"
    name: "Care Package"
    rarity: common
}

api "/give/:player" {
    method: POST
    execute {
        set target to player(request.params.player)
        if target exists {
            give item "care_package" to target
            reply with "delivered"
        } else {
            reply code 404 with "player offline"
        }
    }
}
