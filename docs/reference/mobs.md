# Custom Mobs

A `mob` block declares a reusable mob type: base entity, live nameplate, combat
numbers, AI mode, a drop table, and handlers for its lifecycle. Spawning one is a
single statement.

```swoftlang
mob "crypt_ghoul" {
    type: "ZOMBIE"
    name: "<red>Crypt Ghoul <green>${mob.health}<red>❤"
    health: 200
    damage: 25
    speed: 0.3
    ai: melee

    drops {
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }

    on_death {
        if killer exists {
            send "<green>You slew the Crypt Ghoul!" to killer
        }
    }
}

command "ghoul" {
    execute {
        spawn mob "crypt_ghoul" at location(10, 64, 20) as m
        set m.health to m.max_health / 2
        send "<gray>Spawned ${m.custom_id} at half health." to sender
    }
}
```

## Declaration keys

| Key | Type | Required | Meaning |
|---|---|---|---|
| `type:` | string literal | **yes** | base `EntityType` — `"ZOMBIE"`, `"zombie"`, and `"minecraft:zombie"` all work |
| `name:` | String expression | no | nameplate, always visible; `${mob.health}` re-renders on damage |
| `health:` | Number expression | no | max health |
| `damage:` | Number expression | no | melee hit damage |
| `speed:` | Number expression | no | movement speed attribute |
| `ai:` | enum | no | `melee` (chase + attack + stroll), `passive` (stroll), `none` (statue) |
| `viewable:` | boolean | no | auto-viewable at spawn; `false` spawns it hidden for per-viewer control — see [per-viewer entities](./entities#per-viewer) |
| `tags { ... }` | block | no | **typed** per-entity state — see [Tags](#tags) |
| `drops { ... }` | block | no | rolled on death; see [drops](#drops) |
| `on_spawn { ... }` | statements | no | binds `mob` |
| `on_death { ... }` | statements | no | binds `mob`, `killer` (`optional<Player>`) |
| `on_attack { ... }` | statements | no | binds `mob`, `victim` (`Player`) |
| `on_hit(attacker) { ... }` | statements | no | the mob is damaged; binds `mob` and the named `attacker` (`optional<Player>`) |

The `type:` is validated against the real EntityType registry of the pinned Minestom
snapshot — all 149 constants, with a suggestion when you're close:

```
e_mobtype.sw:2:11: error: unknown entity type 'RAT'; did you mean 'BAT'?
```

## Drops {#drops}

One line per possible drop: `item "<id>" chance <0..1> [amount <n>]`. Ids resolve
against **custom items first**, then vanilla materials — so a declared
[`item`](./items) and `"ROTTEN_FLESH"` sit in the same table:

```swoftlang
item "rotten_scimitar" {
    material: "GOLDEN_SWORD"
    name: "Rotten Scimitar"
    rarity: uncommon
}

mob "armed_ghoul" {
    type: "ZOMBIE"

    drops {
        item "rotten_scimitar" chance 0.05 amount 1
        item "ROTTEN_FLESH" chance 0.5 amount 2
    }
}
```

Every drop rolls independently on death. A literal id that is neither a declared
custom item nor an ALL_CAPS vanilla material name is a compile error:

```
e_drop.sw:4:14: error: unknown item 'not_a_thing_xyz' in drops; declare it with 'item "not_a_thing_xyz" { }' or use an ALL_CAPS vanilla material name
```

## Spawning and despawning

| Form | Effect |
|---|---|
| `spawn mob "id" at <location> [as <var>]` | spawns one instance; `as` binds it as a `Mob` |
| `despawn <mob>` | removes the entity |
| `all_mobs()` | `list<Mob>` — every live custom mob |
| `all_mobs("id")` | `list<Mob>` — live instances of one declaration |

Like `give item`, a literal id in `spawn mob` must name a declaration — unknown ids
are compile errors, not silent no-ops at 2 a.m.

```swoftlang
mob "lost_sheep" {
    type: "SHEEP"
    name: "<yellow>Lost Sheep"
    health: 20
    ai: passive
}

command "cleanse" {
    execute {
        loop all_mobs("lost_sheep") as s {
            despawn s
        }
        send "<green>The pasture is quiet." to sender
    }
}
```

## The Mob value

| Property | Type | Access |
|---|---|---|
| `health` | `Double` | read/write — writing re-renders the nameplate |
| `max_health` | `Double` | read-only |
| `name` | `String` | read/write |
| `location` | `Location` | read/write — writing teleports |
| `type` | `String` | read-only — the base entity type |
| `custom_id` | `String` | read-only — the declaration id |

A `Mob` **composes the [`Entity`](./entities) property table** — it *is* an `Entity`, so
every entity property (`uuid`, `glowing`, `gravity`, `invisible`, `on_fire`, `silent`,
`passengers`, …) reads and writes on a `Mob` value too:

```swoftlang
mob "sentry" {
    type: "IRON_GOLEM"
    health: 100
}

command "sentry" {
    execute {
        // in_front_of(player, distance) is a Location: 'distance' blocks ahead of the eye line
        spawn mob "sentry" at in_front_of(sender, 3) as g
        set g.glowing to true
        set g.gravity to false
        send "spawned ${g.uuid}" to sender
    }
}
```

::: tip Per-mob timers
A `Mob` carries a [task registry](./schedulers#obj-tasks):
`set mob.tasks.<id> to schedule every N ticks { }` (bind it in `on_spawn`) attaches a
named repeating task that auto-cancels when the mob despawns.
:::

## The `on_hit` handler {#on-hit}

`on_hit(<name>) { ... }` runs when the mob takes damage, inline in the declaration. It
binds `mob` and an `attacker` parameter you name — an `optional<Player>`, `none` when the
damage has no player source (fall, fire, another mob):

```swoftlang
mob "guardian" {
    type: "IRON_GOLEM"
    name: "<gold>Guardian"
    health: 100

    on_hit(attacker) {
        if attacker exists {
            send "<red>You struck the ${mob.custom_id}!" to attacker
        }
        set mob.velocity to velocity(0, 0.5, 0)
    }
}
```

It is the per-declaration twin of the global [`MobDamage`](#mob-events) event, which also
now carries `attacker` — `on_hit` for one mob's knockback flavor, `MobDamage` for
cross-mob systems.

## Tags {#tags}

`mob.tags.<name>` is freeform per-entity state — read, set, and delete arbitrary values
on a live mob (or any [`Entity`](./entities)) without declaring a field. A read is
`optional<Any>` (the tag may be unset), a write stores, and `set ... to none` deletes:

```swoftlang
mob "elite" {
    type: "ZOMBIE"
    health: 40
}

command "promote" {
    execute {
        spawn mob "elite" at location(0, 64, 0) as g
        set g.tags.level to 5                    // store
        set lvl to g.tags.level otherwise 0      // read with a fallback
        send "level ${lvl}" to sender
        set g.tags.level to none                 // delete
    }
}
```

Because a tag read is `optional<Any>`, narrow or `otherwise` it before use — using one
directly is a compile error:

```
mob_tags_optional.sw:5:33: error: the left operand of '+' is optional<Any> and may be missing; check it with 'if ... exists' or provide a fallback with 'otherwise'
```

### Typed tags {#typed-tags}

Declaring a `tags { ... }` block on the mob gives a tag a **fixed type** instead of the
freeform `optional<Any>`. Each entry is `name: <Type>` — a typed, indexable store that
starts empty:

```swoftlang
mob "zombie" {
    type: "ZOMBIE"
    viewable: false

    tags: { hits: map<Player, Integer> }      // typed, keyed by Player

    on_hit(attacker) {
        if attacker exists {
            set mob.tags.hits[attacker] to (mob.tags.hits[attacker] otherwise 0) + 1
        }
    }
}
```

Now `mob.tags.hits[attacker]` is `optional<Integer>` — the value type is known, but a key
that was never written is still missing, so the `otherwise 0` fallback stays required.
This `map<Player, Integer>` keyed by player is the backbone of the
[per-viewer zombie](./entities#the-per-viewer-zombie): one counter per attacker on a
single mob. A typed tag and a freeform `mob.tags.<other>` can coexist on the same mob.

## Mob events

Global counterparts to the per-declaration handlers, typed in the
[event table](./syntax-cheatsheet#events) and fired for **every** custom mob:

| Event | Cancellable | Properties on `event` |
|---|---|---|
| `MobSpawn` | no | `mob` |
| `MobDeath` | no | `mob`, `killer` (`optional<Player>`) |
| `MobDamage` | yes | `mob`, `damage` (rw), `attacker` (`optional<Player>`), `cancelled` (rw) |

```swoftlang
persistent kills for Player: Integer = 0

event MobDeath {
    execute {
        if event.killer exists {
            set kills for event.killer to (kills for event.killer) + 1
            send "<gold>${event.mob.custom_id} down — ${kills for event.killer} kills" to event.killer
        }
    }
}

event MobDamage {
    execute {
        if event.mob.custom_id is "lost_sheep" {
            cancel event
        }
    }
}
```

::: tip Per-declaration vs global
`on_death` in the declaration is the right place for behavior that belongs to the mob
(drops flavor, death cries). The `MobDeath` event is the right place for systems that
span all mobs — kill counters, quest progress, leaderboards.
:::
