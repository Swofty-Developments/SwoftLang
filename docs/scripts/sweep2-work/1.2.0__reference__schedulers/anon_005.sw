Player {
    on_join() {
        // bind two named tasks to the joining player
        set this.tasks.welcome to schedule every 20 ticks {
            send "<gray>tick" to this
        }
        set this.tasks.reminder to schedule after 1 seconds every 2 seconds {
            send "<yellow>reminder" to this
        }

        // query by id: 'is running' / 'is not running' is a Boolean
        if this.tasks.welcome is running send "<green>welcome running" to this
        if this.tasks.reminder is not running send "<red>reminder stopped" to this

        // cancel by id — 'cancel' and 'stop' are interchangeable here
        cancel this.tasks.welcome
        stop this.tasks.reminder
    }
}
