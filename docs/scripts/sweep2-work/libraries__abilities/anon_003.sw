import "abilities"

command "wire" {
    execute {
        // a 5-second ability and a 1-second ability, independent cooldowns
        on_item_use("blink_staff", "right", with_cooldown(5.0,
            function(user: Player, held: Item) {
                send "<light_purple>Blink!" to user
            }))
        on_item_use("spark_wand", "right", with_cooldown(1.0,
            function(user: Player, held: Item) {
                send "<yellow>Spark!" to user
            }))
    }
}

item BlinkStaff { material: "BLAZE_ROD" }
item SparkWand { material: "STICK" }
