command "kit" {
    execute {
        give item "aspect_of_the_end" to sender
        send "<green>Kit delivered — right-click to Transmit." to sender
    }
}

command "kit-setup" {
    execute {
        // right-click the Aspect: a 3-second cooldown, then the effect
        on_item_use("aspect_of_the_end", "right", with_cooldown(3.0,
            function(user: Player, held: Item) {
                set dmg to held.tags.damage otherwise 0
                send "<aqua>Instant Transmission! (${dmg} dmg ready)" to user
            }))
        send "<gray>Aspect ability registered." to sender
    }
}
