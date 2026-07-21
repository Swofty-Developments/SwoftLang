Player {
    on_join {
        place block("minecraft:sea_lantern") at player.location
        place "minecraft:oak_log" at player.location
        remove block at player.location
    }
}
