// Phase-7 entity system: spawn/remove/mount/dismount/launch projectile,
// velocity vectors, the Entity property table, and Mob-is-a-Entity narrowing.

command "entities" {
    execute {
        spawn entity "ZOMBIE" at location(0, 64, 0) as z
        send "spawned ${z.type} (${z.uuid})" to sender

        set z.custom_name to "<red>Boss"
        set z.name_visible to true
        set z.glowing to true
        set z.gravity to false
        set z.on_fire to true
        set z.silent to true
        set z.invisible to false
        set z.location to location(10, 65, 10)

        set v to velocity(0.5, 1.5, 0.5)
        set z.velocity to v
        set z.velocity.y to 2.0
        send "vx ${v.x} vy ${v.y} vz ${v.z}" to sender

        if z.alive and not z.removed {
            send "alive at ${z.location.x}" to sender
        }

        spawn entity "PIG" at location(0, 64, 4) as pig
        mount z on pig
        loop z.passengers as rider {
            send "rider: ${rider.type}" to sender
        }
        dismount z

        if z.vehicle exists {
            send "still riding" to sender
        }

        launch projectile "SNOWBALL" from sender with speed 2.5 as ball
        set ball.glowing to true
        launch projectile "ARROW" from sender with velocity velocity(0.0, 1.0, 0.0)
        launch projectile "FIREBALL" from sender

        loop all_entities("SNOWBALL") as e {
            remove entity e
        }
        loop all_entities() as e {
            send "found ${e.type}" to sender
        }

        remove entity pig
    }
}

function quiet_entity(e: Entity) {
    set e.silent to true
    set e.velocity to velocity(0, 0, 0)
}

function describe(x: either<Mob|String>) {
    if x is a Entity {
        // a Mob IS an Entity; narrowing keeps the Mob rows
        send "mob ${x.name} at ${x.location.x} hp ${x.health}" to all
    } else {
        send "not an entity: ${x}" to all
    }
}
