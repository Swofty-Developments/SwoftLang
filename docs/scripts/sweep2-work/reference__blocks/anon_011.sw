placement_rule for "oak_log" {
    on_place(location, face, cursor, against, player) -> Block {
        set axis to "y"
        if (face is "north") or (face is "south") set axis to "z"
        if (face is "east") or (face is "west") set axis to "x"
        return block("oak_log").with("axis", axis)
    }
    self_replaceable: false
}
