command "make" {
    execute {
        set plain to block("oak_stairs")
        set posed to block("oak_stairs", {facing: "north", half: "top", waterlogged: "false"})
        set dir to posed.property("facing")
        send "${plain.id} / ${dir}" to sender
    }
}
