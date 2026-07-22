Player {
    on_join() {
        place block("minecraft:sea_lantern") at this.location
        set block_at(this.location).tasks.pulse to schedule every 5 ticks {
            broadcast "<aqua>pulse"
        }
        if block_at(this.location).tasks.pulse is running broadcast "pulsing"
        remove block at this.location      // also cancels the 'pulse' task
    }
}
