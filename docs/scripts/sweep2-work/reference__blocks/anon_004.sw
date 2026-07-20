command "place" {
    execute {
        set here to block_at(sender.location)
        set block at sender.location to block("oak_stairs", {facing: "north"})
        fill blocks from location(0, 63, 0) to location(2, 63, 2) with block("oak_slab", {type: "double"})
        send "was standing on ${here.id}" to sender
    }
}
