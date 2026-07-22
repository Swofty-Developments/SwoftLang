Player {
    on_join {
        place block("minecraft:sea_lantern") at player.location
        set block_at(player.location).tasks.pulse to schedule every 5 ticks {
            broadcast "<aqua>pulse"
        }
        if block_at(player.location).tasks.pulse is running broadcast "pulsing"
        remove block at player.location      // also cancels the 'pulse' task
    }
}
