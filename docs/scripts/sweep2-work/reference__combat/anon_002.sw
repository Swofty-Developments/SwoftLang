command "buff" {
    execute {
        set spd to attribute(sender, "movement_speed")
        set_attribute(sender, "max_health", 40.0)
        add_attribute_modifier(sender, "movement_speed", "sprint_boost", 0.2, "add_multiplied_base")
        remove_attribute_modifier(sender, "movement_speed", "sprint_boost")
        send "base speed ${spd}" to sender
    }
}
