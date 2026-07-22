Block {
    on_dispense {
        if item.material is "minecraft:arrow" {
            // turn every dispensed arrow into a snowball
            set item to item("SNOWBALL")
        }
    }
}
