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
| `passengers` | `List<Entity>` | ro | who is riding this entity |
| `vehicle` | `Optional<Entity>` | ro | what this entity is riding, if anything |
| `shooter` | `Optional<Entity>` | ro | the launcher, for projectiles; `none` otherwise |
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

`all_entities()` returns every entity in play as a `List<Entity>`; pass a type string to
filter to one kind:

```swoftlang
loop all_entities("SNOWBALL") as leftover {
    remove entity leftover
}
send "entities in the world: ${length(all_entities())}" to all
```

## Per-viewer entities {#per-viewer}

Every entity carries a **viewer set** — the players who have been sent its spawn
packets and therefore see it. By default a spawned entity is auto-viewable: everyone in
range is added as they come and go. Turn that off and the entity becomes yours to hand
out, one player at a time — a mob only its owner can see, a marker only staff notice, a
nameplate that reads differently to each viewer.

| Form | Meaning |
|---|---|
| `viewable: false` (mob/npc/hologram decl key) | spawn **not** auto-viewable — nobody sees it until you `show` it |
| `show <entity> to <player \| all>` | add the target(s) to the viewer set |
| `hide <entity> from <player \| all>` | remove the target(s) from the viewer set |
| `viewers of <entity>` | the current viewer set as a `List<Player>` |
| `set name of <entity> to <string> for <player>` | that viewer's overhead name — per-viewer, `for` is required |

`show` / `hide` and `set name of … for` work on **any** `Entity` value — a mob, a
spawned armor stand, a display. `viewers of` reads Minestom's live `Viewable` set, so it
reflects `show`/`hide` calls and (for auto-viewable entities) whoever is currently in
range.

### The per-viewer zombie

The canonical example: one zombie per player, each with its own private hit counter and
its own nameplate, despawning only for the player who slays it. It leans on four pieces —
`viewable: false` so the spawn is private, a [typed tag](./mobs#tags) keyed by `Player`,
`set name of … for` for the per-viewer nametag, and `hide … from` to retire it for one
viewer:

```swoftlang
mob Zombie {
    type: "ZOMBIE"
    viewable: false                          // spawns hidden — handed out per player

    tags: { hits: Map<Player, Integer> }      // typed per-entity state, keyed by player

    on_hit {
        if attacker exists {
            set mob.tags.hits[attacker] to (mob.tags.hits[attacker] otherwise 0) + 1
            set count to mob.tags.hits[attacker] otherwise 0

            // only this attacker sees this nameplate
            set name of mob to "<red>Zombie <gray>${count}/5" for attacker

            if count >= 5 {
                hide mob from attacker                    // gone for them only
                send "<green>You slew your zombie!" to attacker
            }
        }
    }
}

Player {
    on_join {
        spawn mob Zombie at in_front_of(player, 5) as z
        set name of z to "<red>Zombie <gray>0/5" for player
        show z to player                                    // reveal it to just this player
    }
}
```

Because the zombie is `viewable: false`, the `spawn` puts it in the world seen by nobody;
the `show z to player` line is what makes it appear, and only for the joining
player. Two players standing side by side each punch their *own* zombie: the tag map is
keyed by `Player`, so `mob.tags.hits[attacker]` counts per attacker, and the
`set name … for attacker` nameplate updates for that attacker alone.

::: tip Typed tags are per-viewer-friendly
`tags { hits: Map<Player, Integer> }` declares a **typed** tag store (unlike the freeform
`mob.tags.<name>` — see [Tags](./mobs#tags)). A key that has never been written reads as
`Optional<Integer>`, so `otherwise 0` (or an `if … exists` narrow) is required — using it
bare is a compile error:

```
e.sw:6:35: error: the left operand of '+' is Optional<Integer> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
```
:::

### Reading and revealing to many

`viewers of` gives you the set back as a `List<Player>` — loop it, count it, or reveal an
entity to an audience with `show … to all`:

```swoftlang
mob Sentinel {
    type: "IRON_GOLEM"
    viewable: false
}

command "audience" {
    execute {
        spawn mob Sentinel at in_front_of(sender, 3) as g
        show g to sender
        loop viewers of g as watcher {
            send "<gray>${watcher.name} can see the sentinel" to watcher
        }
        send "<yellow>viewers: ${length(viewers of g)}" to sender
    }
}
```

`show <entity> to all` adds every online player (and, for an auto-viewable entity, keeps
tracking new joins); `hide <entity> from all` clears the set. Both take a single `Player`
just as happily as `all`.

### Per-viewer names on plain entities

`set name of … for` isn't mob-only — it sets the overhead name of any entity for one
viewer. A marker only the person who spawned it can read:

```swoftlang
command "ghost" {
    execute {
        spawn entity "ARMOR_STAND" at in_front_of(sender, 2) as ghost
        set ghost.name_visible to true
        set name of ghost to "<gray>only you see me" for sender
        show ghost to sender
    }
}
```

::: tip `set name of … for` vs nametags
`set name of <entity> to … for <player>` drives the entity's own **overhead name**
(entity metadata), so it works on any entity — armor stands, mobs, displays. The
separate [nametag statements](./nametags) drive a **player's** team-based nameplate
(prefix/suffix/color), and their `for` clause is optional. Reach for entity names on
mobs and props; reach for nametags on players.
:::

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
function inspect(x: Either<Mob|String>) {
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

::: tip Per-entity timers
Any `Entity` (and therefore any `Mob`) carries a
[task registry](./schedulers#obj-tasks):
`set <entity>.tasks.<id> to schedule every N ticks { }` binds a named repeating task that
auto-cancels when the entity is removed.
:::
