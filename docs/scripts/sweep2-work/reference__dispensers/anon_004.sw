Block {
    on_dispense(item, direction) {
        if item.material is "minecraft:arrow" {
            // turn every dispensed arrow into a snowball
            set item to item("SNOWBALL")
        }
    }
}
