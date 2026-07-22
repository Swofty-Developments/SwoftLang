Player {
    on_join {
        // bind two named tasks to the joining player
        set player.tasks.welcome to schedule every 20 ticks {
            send "<gray>tick" to player
        }
        set player.tasks.reminder to schedule after 1 seconds every 2 seconds {
            send "<yellow>reminder" to player
        }

        // query by id: 'is running' / 'is not running' is a Boolean
        if player.tasks.welcome is running send "<green>welcome running" to player
        if player.tasks.reminder is not running send "<red>reminder stopped" to player

        // cancel by id — 'cancel' and 'stop' are interchangeable here
        cancel player.tasks.welcome
        stop player.tasks.reminder
    }
}
