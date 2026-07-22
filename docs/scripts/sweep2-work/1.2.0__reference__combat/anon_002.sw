command "buff" {
    execute {
        set spd to sender.movement_speed
        set sender.max_health to 40.0
        add modifier "sprint_boost" to sender.movement_speed of 0.2 add_multiplied_base
        remove modifier "sprint_boost" from sender.movement_speed
        send "base speed ${spd}" to sender
    }
}
