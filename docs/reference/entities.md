# Entities

An `Entity` is any live thing in a world — a spawned armor stand, a dropped item, a
launched projectile, a boat, a mob. SwoftLang gives every entity one shared property
table and a small set of statements to spawn, move, ride, and remove them. Custom
[mobs](./mobs) are entities too: `Mob` is a subtype of `Entity`, so every row on this
page also works on a `Mob` value.

```swoftlang
spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
set stand.custom_name to "<gold>Landmark"
set stand.name_visible to true
set stand.glowing to true
```

## The `Entity` value

| Property | Type | Access | Meaning |
|---|---|---|---|
| `type` | `String` | ro | entity type, e.g. `"ARMOR_STAND"` |
| `uuid` | `String` | ro | the entity's UUID |
| `location` | `Location` | rw | position + orientation; writing teleports |
| `velocity` | `Vec` | rw | motion in blocks-per-tick; writing sets it |
| `custom_name` | `String` | rw | the nameplate text (MiniMessage) |
| `name_visible` | `Boolean` | rw | show the nameplate |
| `glowing` | `Boolean` | rw | outline glow |
| `invisible` | `Boolean` | rw | hide the model |
| `gravity` | `Boolean` | rw | whether gravity applies |
| `on_fire` | `Boolean` | rw | burning visual + damage |
| `silent` | `Boolean` | rw | mute the entity's sounds |
| `passengers` | `list<Entity>` | ro | who is riding this entity |
| `vehicle` | `optional<Entity>` | ro | what this entity is riding, if anything |
| `shooter` | `optional<Entity>` | ro | the launcher, for projectiles; `none` otherwise |
| `alive` | `Boolean` | ro | still living |
| `removed` | `Boolean` | ro | removed from its world |

```swoftlang
spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
set stand.custom_name to "<gold>Landmark"
set stand.name_visible to true
set stand.glowing to true
set stand.gravity to false
set stand.invisible to false
set stand.silent to true
```

The `type` string accepts every `EntityType` in the pinned engine registry, in any of
the usual spellings — `"ARMOR_STAND"`, `"armor_stand"`, and `"minecraft:armor_stand"`
all name the same type, and an unknown type is a compile error with a suggestion.

## Velocity vectors

`velocity(x, y, z)` builds a `Vec` — three blocks-per-tick components, exactly
Minecraft's convention. A `Vec` has read/write `x`, `y`, `z` fields, so you can build
one, tweak an axis, and assign it to an entity's `velocity`:

```swoftlang
set v to velocity(0.5, 1.5, -0.5)
set v.y to 3.0
set total to v.x + v.y + v.z
```

```swoftlang
spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
set stand.velocity to velocity(0.0, 0.5, 0.0)
set stand.velocity.y to 1.0
```

## Spawning, moving, removing

| Statement | Effect |
|---|---|
| `spawn entity "TYPE" at <location> [as <var>]` | spawns one entity; `as` binds it as an `Entity` |
| `remove entity <entity>` | despawns the entity |
| `mount <rider> on <vehicle>` | seats one entity on another |
| `dismount <rider>` | removes the rider from its vehicle |

```swoftlang
spawn entity "minecraft:pig" at location(4.5, 65.0, 4.5) as mount_pig
spawn entity "ARMOR_STAND" at location(4.5, 65.0, 4.5) as stand
mount stand on mount_pig
loop mount_pig.passengers as rider {
    send "riding: ${rider.type}" to all
}
if stand.vehicle exists {
    send "the statue found a ride" to all
}
dismount stand
remove entity stand
remove entity mount_pig
```

Writing `location` teleports; reading it back reflects where the entity now is:

```swoftlang
spawn entity "ARMOR_STAND" at location(0.5, 64.0, 0.5) as stand
set stand.location to location(4.5, 65.0, 4.5)
if stand.alive and not stand.removed {
    send "statue stands at x=${stand.location.x}" to all
}
```

## Launching projectiles

`launch projectile "TYPE" from <shooter>` fires a projectile entity. With no velocity
clause it flies along the shooter's look direction at a default speed; add
`with speed <n>` to scale that direction, or `with velocity <vec>` to set the motion
outright. Bind the result with `as` to keep working with it:

```swoftlang
launch projectile "SNOWBALL" from sender with speed 2.5 as ball
set ball.glowing to true
send "lobbed a ${ball.type}" to sender

launch projectile "ARROW" from sender with velocity velocity(0.0, 1.0, 0.0)
launch projectile "FIREBALL" from sender
```

A launched projectile's `shooter` points back at whoever fired it, and its flight and
impact surface as the [`EntityShoot`, `ProjectileCollideWithBlock`, and
`ProjectileCollideWithEntity` events](./events#the-generated-catalog).

## Querying the world

`all_entities()` returns every entity in play as a `list<Entity>`; pass a type string to
filter to one kind:

```swoftlang
loop all_entities("SNOWBALL") as leftover {
    remove entity leftover
}
send "entities in the world: ${length(all_entities())}" to all
```

## Mobs are entities

Because `Mob` is a subtype of `Entity`, a function that takes an `Entity` accepts a mob,
and every `Entity` row resolves on a mob value on top of its own [typed mob
rows](./mobs#the-mob-value):

```swoftlang
function becalm(e: Entity) {
    set e.silent to true
    set e.on_fire to false
    set e.velocity to velocity(0.0, 0.0, 0.0)
}
```

`is a Entity` is a runtime check that narrows in the checker, so a value that might be a
mob can be handled as an entity where it is one:

```swoftlang
function inspect(x: either<Mob|String>) {
    if x is a Entity {
        // the typed Mob rows and the shared Entity rows both apply here
        send "mob ${x.name} (${x.type})" to all
    } else {
        send "not an entity: ${x}" to all
    }
}
```

::: tip Displays are entities
The text/item/block [display entities](./displays) are spawned entities too — a
`Display` value can be mounted, teleported, and removed with the same statements.
:::
