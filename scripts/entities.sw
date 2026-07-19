// Phase-7 entity system showcase: spawn/remove any Minestom entity type,
// velocity vectors, the shared Entity property table, mount/dismount,
// projectile launching, and all_entities() queries. Mob stays a subtype:
// every Entity row also resolves on mobs.

// Pure vector math — velocity() is engine-free, so this command runs
// (and its values verify) even in the headless harness.
command "vectors" {
    execute {
        set v to velocity(0.5, 1.5, -0.5)
        send "cast vector: x=${v.x} y=${v.y} z=${v.z}" to sender
        set v.y to 3.0
        send "tweaked: x=${v.x} y=${v.y} z=${v.z}" to sender
        set total to v.x + v.y + v.z
        send "component sum: ${total}" to sender
    }
}

// Spawn a decorated statue, give it a ride, then clean up.
command "statue" {
    execute {
        spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
        send "spawned ${stand.type} (${stand.uuid})" to sender

        set stand.custom_name to "<gold>Landmark"
        set stand.name_visible to true
        set stand.glowing to true
        set stand.gravity to false
        set stand.invisible to false
        set stand.silent to true

        set stand.velocity to velocity(0.0, 0.5, 0.0)
        set stand.velocity.y to 1.0
        set stand.location to location(4.5, 65.0, 4.5)

        spawn entity "minecraft:pig" at location(4.5, 65.0, 4.5) as mount_pig
        mount stand on mount_pig
        loop mount_pig.passengers as rider {
            send "riding: ${rider.type}" to sender
        }
        if stand.vehicle exists {
            send "the statue found a ride" to sender
        }
        dismount stand

        if stand.alive and not stand.removed {
            send "statue stands at x=${stand.location.x}" to sender
        }
        remove entity mount_pig
        remove entity stand
    }
}

// Projectiles: default speed from the look direction, explicit speed,
// or a full velocity vector.
command "volley" {
    execute {
        launch projectile "SNOWBALL" from sender with speed 2.5 as ball
        set ball.glowing to true
        send "lobbed a ${ball.type}" to sender

        launch projectile "ARROW" from sender with velocity velocity(0.0, 1.0, 0.0)
        launch projectile "FIREBALL" from sender

        loop all_entities("SNOWBALL") as leftover {
            remove entity leftover
        }
        send "entities in the world: ${length(all_entities())}" to sender
    }
}

// Entity rows resolve on anything alive — including mobs (Mob IS-A Entity).
function becalm(e: Entity) {
    set e.silent to true
    set e.on_fire to false
    set e.velocity to velocity(0.0, 0.0, 0.0)
}

function inspect(x: either<Mob|String>) {
    if x is a Entity {
        // narrowing keeps the typed Mob rows while Entity rows still apply
        send "mob ${x.name} (${x.type}) hp ${x.health}" to all
    } else {
        send "not an entity: ${x}" to all
    }
}
