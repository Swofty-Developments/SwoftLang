command "blocks" {
    execute {
        set b to block("oak_stairs", {facing: "north", half: "top"})
        set dir to b.property("facing")
        set block at sender.location to b
        send "placed ${b.id} facing ${dir}" to sender
    }
}
