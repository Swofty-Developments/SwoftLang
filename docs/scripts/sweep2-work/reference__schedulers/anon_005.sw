on PlayerJoin {
    // bind two named tasks to the joining player
    set event.player.tasks.welcome to schedule every 20 ticks {
        send "<gray>tick" to event.player
    }
    set event.player.tasks.reminder to schedule after 1 seconds every 2 seconds {
        send "<yellow>reminder" to event.player
    }

    // query by id: 'is running' / 'is not running' is a Boolean
    if event.player.tasks.welcome is running send "<green>welcome running" to event.player
    if event.player.tasks.reminder is not running send "<red>reminder stopped" to event.player

    // cancel by id — 'cancel' and 'stop' are interchangeable here
    cancel event.player.tasks.welcome
    stop event.player.tasks.reminder
}
