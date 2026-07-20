command "effects" {
    execute {
        apply_effect(sender, "strength", 200, 0, true, false)
        loop active_effects(sender) as e {
            send "active: ${e}" to sender
        }
        remove_effect(sender, "strength")
    }
}
