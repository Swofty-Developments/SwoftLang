import "abilities"

command "wire" {
    execute {
        on_item_use("aspect_of_the_end", "right",
            function(user: Player, held: Item) {
                set dmg to held.tags.damage otherwise 0
                send "<aqua>Transmission for ${dmg} damage!" to user
            })
    }
}

item "aspect_of_the_end" { material: "DIAMOND_SWORD" tags { damage: 100 } }
