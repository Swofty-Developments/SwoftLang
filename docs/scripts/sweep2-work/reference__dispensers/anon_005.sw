Block {
    on_dispense(item, direction) {
        if this.id is "minecraft:dropper" {
            cancel event
        }
    }
}
