command "inspect" {
    execute {
        set b to block("oak_stairs")
            .with("facing", "east")
            .with("half", "top")
        set facing to b.property("facing")
        set props to b.properties
        set kind to b.id
        set b to b.with_nbt("{}")
        set b to b.with_tag("owner", "swofty")
        set tag to b.get_tag("owner")
        send "${kind} facing ${facing}, owner ${tag}" to sender
    }
}
