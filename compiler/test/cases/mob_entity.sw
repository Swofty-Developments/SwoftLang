// Mob composes the ENTITY property table (Mob <: Entity), entity/mob tags, the
// on_hit handler, the MobDamage 'attacker' row, and in_front_of().

mob Guardian {
    type: "IRON_GOLEM"
    name: "<gold>Guardian"
    health: 100

    on_spawn {
        // entity rows compose onto Mob values
        set mob.glowing to true
        set mob.gravity to false
    }

    on_hit {
        // attacker is optional<Player>
        if attacker exists {
            send "You struck the ${mob.custom_id}!" to attacker
        }
        set mob.velocity to velocity(0, 0.5, 0)
    }
}

command "guard" {
    execute {
        // in_front_of(player, distance) is a Location builtin
        spawn mob Guardian at in_front_of(sender, 3) as g

        // composed Entity rows on a Mob value
        send "uuid ${g.uuid}" to sender
        set g.invisible to false
        set g.on_fire to true
        set g.silent to true
        loop g.passengers as rider {
            send "rider ${rider.type}" to sender
        }

        // freeform entity/mob tags: get(optional<Any>) / set / delete
        set g.tags.level to 5
        set lvl to g.tags.level otherwise 0
        send "level ${lvl}" to sender
        set g.tags.level to none
    }
}

Mob {
    on_hit {
        broadcast "${mob.type} attacked by ${attacker}"
    }
}
