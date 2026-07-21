Player {
    on_join() {
        place block("minecraft:sea_lantern") at this.location
        place "minecraft:oak_log" at this.location
        remove block at this.location
    }
}
