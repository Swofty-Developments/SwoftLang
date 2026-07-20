command "smite" {
    execute {
        set landed to apply_damage(sender, 6.0, "magic")
        if landed {
            apply_knockback(sender, 0.5, 1.0, 0.0)
            apply_effect(sender, "regeneration", 100, 1)
        }
        set arrow to spawn_projectile("arrow", sender.location, velocity(0, 1, 2), sender)
        send "spawned ${arrow}" to sender
    }
}
