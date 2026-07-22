Item {
    on_use {
        if custom_id(item) otherwise "" is "aspect_of_the_end" {
            send "<gray>You used the Aspect!" to player
        }
    }
}
