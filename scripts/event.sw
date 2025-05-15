event PlayerChat {
    priority: 0

    execute {
        // Modify the message
        set event.message to "[Filtered] ${event.message}"

        // Send feedback to the player
        send "You said: ${event.message}" to event.player

        // Conditional cancellation
        if event.message contains "badword" {
            send "<red>Your message was blocked!" to event.player
            cancel event
        }
    }
}

event PlayerJoin {
    priority: 5

    execute {
        send "<green>Welcome ${event.player.name.content}!" to all
        send "Hello ${event.player.name.content}!" to event.player
    }
}