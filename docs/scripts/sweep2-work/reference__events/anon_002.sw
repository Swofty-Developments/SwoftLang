// these two declarations listen to exactly the same class
event PlayerFinishItemUse {
    execute {
        send "reeled in after ${event.use_duration} ticks" to event.player
    }
}
