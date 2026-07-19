import "abilities"

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    name: "<blue>Aspect of the End"
    rarity: rare
    glint: true
}

command "kit-setup" {
    execute {
        on_item_use("aspect_of_the_end", "right", with_cooldown(3.0,
            function(user: Player, held: Item) {
                send "<aqua>Instant Transmission! Whoosh." to user
            }))
        send "<gray>Aspect ability registered." to sender
    }
}
