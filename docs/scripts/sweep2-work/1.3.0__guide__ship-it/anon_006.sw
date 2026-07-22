command "event-start" {
    permission: "myserver.admin"

    execute {
        set job to schedule after 10 seconds every 60 seconds {
            broadcast "<gold>The event is live — /warp event"
        }
        cancel schedule job
    }
}
