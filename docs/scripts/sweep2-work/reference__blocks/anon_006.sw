placement_rule for "oak_stairs" {
    on_place(location, face, cursor, against, player) -> Block {
        return block("oak_stairs").with("facing", "north").with("half", "top")
    }
    on_update(location, block, neighbors) -> Block {
        return block
    }
    self_replaceable: false
}
