Player {
    on_chat(message) {
        // Modify the message
        set message to "[Filtered] ${message}"

        // Send feedback to the player
        send "You said: ${message}" to this

        // Conditional cancellation
        if message contains "badword" {
            send "<red>Your message was blocked!" to this
            cancel event
        }
    }

    on_join() {
        send "<green>Welcome ${this.name}!" to all
        send "Hello ${this.name}!" to this
    }
}
