command "remind" {
    arguments {
        text: String
    }
    execute {
        set who to sender
        set what to args.text
        set ignored to schedule after 60 seconds {
            send "<yellow>Reminder: ${what}" to who
        }
        send "<gray>Reminder set." to sender
    }
}
