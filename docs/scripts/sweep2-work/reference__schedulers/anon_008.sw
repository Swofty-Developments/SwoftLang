on PlayerJoin {
    place block("minecraft:sea_lantern") at event.player.location
    set block_at(event.player.location).tasks.pulse to schedule every 5 ticks {
        broadcast "<aqua>pulse"
    }
    if block_at(event.player.location).tasks.pulse is running broadcast "pulsing"
    remove block at event.player.location      // also cancels the 'pulse' task
}
