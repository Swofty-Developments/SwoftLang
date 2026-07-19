event PlayerUseItem {
    execute {
        if custom_id(event.item) otherwise "" is "aspect_of_the_end" {
            send "<gray>You used the Aspect!" to event.player
        }
    }
}
