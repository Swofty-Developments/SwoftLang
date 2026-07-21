command "blocks" {
    execute {
        set b to block("oak_stairs")
        set b to b.with("facing", "north")
        set b to block("oak_stairs", {facing: "north", half: "top", waterlogged: "false"})
        set facing to b.property("facing")
        set props to b.properties
        set kind to b.id
        set data to b.nbt
        set b to b.with_nbt("{}")
        set tag to b.get_tag("custom")
        set b to b.with_tag("custom", "value")
        set here to block_at(sender.location)
        set block at sender.location to b
        set block at sender.location to "STONE"
        fill blocks from location(0, 63, 0) to location(2, 63, 2) with block("oak_slab", {type: "double"})
    }
}

block_handler "oak_sign" {
    on_place {
        send "placed a sign" to player
    }
    on_destroy {
        broadcast "a sign broke"
    }
    on_interact -> Boolean {
        send "you clicked the sign" to player
        return true
    }
    on_touch {
        broadcast "something touched a sign"
    }
    tick {
        broadcast "sign tick"
    }
}

placement_rule for "oak_stairs" {
    on_place -> Block {
        return block("oak_stairs").with("facing", "north").with("half", "top")
    }
    on_update -> Block {
        return block
    }
    self_replaceable: false
}
