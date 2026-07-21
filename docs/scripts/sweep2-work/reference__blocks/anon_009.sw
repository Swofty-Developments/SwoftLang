placement_rule for "oak_stairs" {
    on_place -> Block {
        return block("oak_stairs").with("facing", "north").with("half", "top")
    }
    on_update -> Block {
        return block
    }
    self_replaceable: false
}
