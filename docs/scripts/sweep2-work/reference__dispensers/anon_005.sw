Block {
    on_dispense {
        if block.id is "minecraft:dropper" {
            cancel event
        }
    }
}
