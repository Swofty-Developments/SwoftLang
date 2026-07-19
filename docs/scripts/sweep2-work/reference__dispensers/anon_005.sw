event BlockDispense {
    execute {
        if event.block is "dropper" {
            cancel event
        }
    }
}
