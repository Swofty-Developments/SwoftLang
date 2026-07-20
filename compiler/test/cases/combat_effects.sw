// W-pvp combat surface (refactored): attribute keys are DIRECT rw entity/player
// properties (read = current value, set = base value), the native trackers are
// ro properties, and the combat effects are English statement verbs
// (damage / knock / apply / remove / shoot) plus the add/remove modifier forms.

command "combat" {
    execute {
        // attribute keys as direct properties: read current, set base
        set base to sender.armor
        set sender.max_health to 40.0
        set sender.attack_damage to sender.attack_damage + 2.0
        send "armor: ${base}" to sender

        // named attribute modifiers with the three operations
        add modifier "rage" to sender.attack_damage of 4.0 add_multiplied_base
        add modifier "shield" to sender.armor of 2.0 add
        add modifier "focus" to sender.attack_speed of 0.5 add_multiplied_total
        remove modifier "rage" from sender.attack_damage

        // trackers: read-only properties
        if sender.invulnerable_ticks > 0 {
            send "i-frames: ${sender.invulnerable_ticks}" to sender
        }
        send "fell ${sender.fall_distance} blocks" to sender
        if sender.is_climbing {
            send "climbing" to sender
        }
        loop sender.active_effects as effect {
            send "active: ${effect}" to sender
        }

        // combat effect verbs: damage with and without type/source
        damage sender by 6.0
        damage sender by 2.0 as "magic"
        damage sender by 3.0 as "player_attack" from sender

        // vanilla-style knockback away from a point
        knock sender away from location(0, 64, 0)
        knock sender away from location(0, 64, 0) with strength 0.8

        // potion effects
        apply "strength" 0 to sender for 200
        apply "regeneration" 1 to sender for 100
        remove "strength" from sender

        // spawn a projectile at a location with an explicit velocity + shooter
        set here to location(0, 64, 0)
        shoot "arrow" from here with velocity velocity(0, 0, 1.5) by sender
        shoot "snowball" from here

        // works over any live entity too: attribute properties, modifiers, and
        // the effect verbs all resolve on a general Entity
        loop all_entities() as e {
            set e.armor to 5.0
            add modifier "weaken" to e.attack_damage of 1.0 add
            remove modifier "weaken" from e.attack_damage
            apply "glowing" 0 to e for 40
            damage e by 1.0
            knock e away from here
        }
    }
}
