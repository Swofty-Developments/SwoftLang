event BlockDispense {
    execute {
        if event.item exists {
            if event.item.material is "minecraft:arrow" {
                // turn every dispensed arrow into a snowball
                set event.item to item("SNOWBALL")
            }
        }
    }
}
