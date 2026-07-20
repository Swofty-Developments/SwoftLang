command "shout" {
    execute {
        send uppercase("swoft") + "!" to sender        // SWOFT!
        send lowercase(sender.name) to sender
    }
}
