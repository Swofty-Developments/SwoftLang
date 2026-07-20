// W-pvp combat EFFECTS: apply_damage / apply_knockback / apply_effect /
// remove_effect / active_effects / spawn_projectile. Damage-type, potion-effect
// and projectile-type literals are validated against the registry; entity
// arguments accept any live entity. apply_damage flows to Boolean,
// active_effects to list<String>, spawn_projectile to the spawned Entity.

command "combat" {
    execute {
        // typed damage, with and without a source entity
        set landed to apply_damage(sender, 6.0, "player_attack")
        if landed {
            apply_damage(sender, 2.0, "magic", sender)
        }

        // vanilla-style knockback vector
        apply_knockback(sender, 0.4, 1.0, 0.0)

        // potion effects: 4-, 5-, and 6-arg forms
        apply_effect(sender, "strength", 200, 0)
        apply_effect(sender, "regeneration", 100, 1, true)
        apply_effect(sender, "speed", 100, 0, false, true)
        remove_effect(sender, "strength")

        loop active_effects(sender) as effect {
            send "active: ${effect}" to sender
        }

        // spawn a projectile at a location with an explicit velocity + owner
        set here to location(0, 64, 0)
        set arrow to spawn_projectile("arrow", here, velocity(0, 0, 1.5), sender)
        set snowball to spawn_projectile("snowball", here, velocity(1, 0, 0))
        send "spawned ${arrow} and ${snowball}" to sender

        // works over any live entity too
        loop all_entities() as e {
            apply_effect(e, "glowing", 40, 0)
        }
    }
}
