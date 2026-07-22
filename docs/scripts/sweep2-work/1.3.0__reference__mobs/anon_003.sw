mob "lost_sheep" {
    type: "SHEEP"
    name: "<yellow>Lost Sheep"
    health: 20
    ai: passive
}

command "cleanse" {
    execute {
        loop all_mobs("lost_sheep") as s {
            despawn s
        }
        send "<green>The pasture is quiet." to sender
    }
}
