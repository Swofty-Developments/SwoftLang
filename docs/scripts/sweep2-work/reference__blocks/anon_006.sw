on PlayerJoin {
    place block("minecraft:sea_lantern") at event.player.location
    place "minecraft:oak_log" at event.player.location
    remove block at event.player.location
}
