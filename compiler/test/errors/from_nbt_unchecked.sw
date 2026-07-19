command "x" {
    execute {
        set restored to from_nbt("{}")
        send to_nbt(restored) to sender
    }
}
