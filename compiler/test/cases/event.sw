Player {
    on_chat {
        // Modify the message
        set message to "[Filtered] ${message}"

        // Send feedback to the player
        send "You said: ${message}" to player

        // Conditional cancellation
        if message contains "badword" {
            send "<red>Your message was blocked!" to player
            cancel event
        }
    }

    on_join {
        send "<green>Welcome ${player.name}!" to all
        send "Hello ${player.name}!" to player
    }
}
