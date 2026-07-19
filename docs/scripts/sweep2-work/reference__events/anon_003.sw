event PlayerFinishItemUseEvent {
    execute {
        send "reeled in after ${event.use_duration} ticks" to event.player
    }
}
