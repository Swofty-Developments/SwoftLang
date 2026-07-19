event PlayerUseItem {
    execute {
        if event.custom_id otherwise "" is "aspect_of_the_end" {
            send "<gray>You used the Aspect!" to event.player
        }
    }
}
