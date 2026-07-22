import "abilities"

item "aspect_of_the_end" {
    material: "DIAMOND_SWORD"
    rarity: rare
}

command "kit-setup" {
    execute {
        on_item_use("aspect_of_the_end", "right",
            function(user: Player, held: Item) {
                send "<aqua>Instant Transmission! Whoosh." to user
            })
    }
}
