event PlayerCatchFish {
    execute {
        if event.caught_mob exists {
            send "<red>brace yourself..." to player
            halt
        }
        if event.caught_item exists {
            send "you landed ${event.caught_item.name}!" to player
            if event.caught_item.material is "minecraft:pufferfish" {
                set event.caught_item to item("COD")
                send "<gray>...swapped the puffer for a safer cod." to player
            }
        }
    }
}
