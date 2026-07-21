---
title: Player & World Properties
---

<StepHeader>
a <code>/wall</code> command that teleports with a one-line write — plus three real compile errors that never reach your server.
</StepHeader>

Dotted chains — `player.location.y`, `args.target.held_item.amount` — are how
scripts read and write game state. They look like field access; under the hood every hop
goes through a **property registry**: a closed, typed table of what each kind of value
exposes, which hops are writable, how values are coerced, and which thread the real
server call must run on.

The compiler ships a copy of that table. Every chain in your script is checked at
compile time — unknown properties, read-only writes, and type mismatches never reach the
server.

## Reading

```swoftlang
Player {
    on_chat {
        send "you are ${player.name} at y=${player.location.y}" to player
        send "holding ${player.held_item.material}" to player
    }
}
```

Chains resolve left to right: `player` → the `Player` the method is about, `.location` → a
`Location` snapshot, `.y` → a `Double`. Interpolated `${...}` paths are the same chains
with the same checks.

Misspell a hop and the compiler answers with a suggestion:

<!-- swoftc name=ping.sw expect=error -->

```swoftlang
Player {
    on_chat {
        send "ping: ${player.latencey}ms" to player   // [!code error]
    }
}
```

```txt
ping.sw:3:14: error: unknown property 'latencey' on Player; did you mean 'latency'?
        send "ping: ${player.latencey}ms" to player
             ^
```

## Writing

`set <chain> to <value>` writes through the same table:

```swoftlang
Player {
    on_chat {
        set player.health to player.max_health
        set player.gamemode to "creative"
        set player.held_item.amount to 32
    }
}
```

Values are coerced and validated per property: numbers clamp to sane ranges (health to
`0..max_health`, item amounts to `1..99`), and enum-like strings are checked **at
compile time**:

<!-- swoftc name=gm.sw expect=error -->

```swoftlang
command "gm" {
    execute {
        if sender is a Player {
            set sender.gamemode to "hardcore"   // [!code error]
        }
    }
}
```

```txt
gm.sw:4:36: error: invalid gamemode 'hardcore'; valid values: survival, creative, adventure, spectator
            set sender.gamemode to "hardcore"
                                   ^
```

Read-only properties refuse writes the same way:

<!-- swoftc name=rename.sw expect=error -->

```swoftlang
Player {
    on_chat {
        set player.name to "Somebody"   // [!code error]
    }
}
```

```txt
rename.sw:3:20: error: property 'name' on Player is read-only
        set player.name to "Somebody"
                   ^
```

In Skript each property has its own expression syntax, and a wrong guess fails at
runtime; here it's one `set ... to` shape over a checked table:

<MappedCompare>
<MappedPair label="reading and writing player state">
<template #skript>

```skript
command /vitals:
    trigger:
        send "you are at y=%y-coordinate of player%"
        set player's gamemode to creative
        heal player
        set player's level to 10
```

</template>
<template #swoftlang>

```swoftlang
command "vitals" {
    execute {
        if sender is a Player {
            send "you are at y=${sender.location.y}"
            set sender.gamemode to "creative"
            set sender.health to sender.max_health
            set sender.level to 10
        }
    }
}
```

</template>
<template #note>

Skript has a bespoke phrase per property (`y-coordinate of`, `heal`, possessives);
SwoftLang has one chain syntax, and the compiler knows every valid hop — so typos get
did-you-mean suggestions instead of "can't understand this expression" at reload time.

</template>
</MappedPair>
</MappedCompare>

## How `set player.location.x` actually works

Some values in the chain are immutable — a `Location` is a snapshot record, an `Item` is
an immutable stack. You can still write *through* them:

```swoftlang
command "wall" {
    execute {
        if sender is a Player {
            set sender.location.x to 100.5
        }
    }
}
```

The runtime resolves the chain and finds the deepest hop that has a real setter — the
**anchor**. Here that's `location`, whose setter is *teleport*. Hops past the anchor are
copy hops: read the current position, copy it with `x` replaced, teleport once — y, z,
yaw, and pitch preserved, all within a single tick. The same mechanism drives
`set sender.held_item.amount to 32`: read held item, copy with the new amount, set in
hand.

::: warning Snapshots don't move players
`set sender.location.x to ...` **teleports**, because the anchor is the player. But a
location stored in a variable is just a snapshot — writing to it updates the *variable*
and nothing else:

```swoftlang
Player {
    on_chat {
        set spot to player.location
        set spot.y to 300.0
        send "spot.y = ${spot.y}, and you have not moved" to player
    }
}
```

Here the anchor is the local variable `spot`, so the copy lands back in the variable. To
actually move someone using a snapshot: `set player.location to spot` (or
`teleport player to spot`).
:::

## World properties

`world(name)` looks a world up (it's an `optional<World>` —
[Step 07](/1.3.0/guide/options) applies), and worlds expose time control:

```swoftlang
command "day" {
    execute {
        set w to world("lobby")
        if w exists {
            set w.time to 1000
            set w.time_rate to 1
            send "<yellow>Sunrise." to sender
        }
    }
}
```

Creating and loading worlds is a deployment concern — that's
[Step 16](/1.3.0/guide/ship-it#worlds).

## Threading

Every property row carries a thread policy. Reads and packet-only writes are safe from
any thread; world-mutating writes (teleport, health, gamemode, inventory) are tick-only
and are automatically dispatched to the tick thread when a script runs
[async](/1.3.0/guide/async#what-runs-where). You never write dispatch code — the table does it.

## The property tables

What the registry — and therefore the compiler — recognizes:

### `Player`

| Property | Type | Access |
|---|---|---|
| `name` | String | read-only |
| `uuid` | String | read-only |
| `health` | Double | read/write (clamped `0..max_health`) |
| `max_health` | Double | read/write |
| `food` | Integer | read/write (clamped `0..20`) |
| `food_saturation` | Double | read/write |
| `level` | Integer | read/write |
| `exp` | Double | read/write (`0.0..1.0`) |
| `gamemode` | String | read/write (`survival`/`creative`/`adventure`/`spectator`) |
| `location` | Location | read/write (write = teleport) |
| `world` | World | read/write (write = instance transfer) |
| `held_item` | Item | read/write |
| `held_slot` | Integer | read/write (`0..8`) |
| `latency` | Integer | read-only |
| `display_name` | String | read/write |
| `flying` | Boolean | read/write |
| `allow_flying` | Boolean | read/write |
| `flying_speed` | Double | read/write |
| `online` | Boolean | read-only |
| `skin` | Skin | read/write (from `skin(texture, signature)` or async `fetch_skin(name)`) |

### `Location`

| Property | Type | Access |
|---|---|---|
| `x`, `y`, `z` | Double | read/write (copy hop) |
| `yaw`, `pitch` | Double | read/write (copy hop; pitch clamped `-90..90`) |
| `block_x`, `block_y`, `block_z` | Integer | read-only (derived) |

### `Item`

| Property | Type | Access |
|---|---|---|
| `material` | String | read/write (accepts `stone` or `minecraft:stone`) |
| `amount` | Integer | read/write (`1..99`) |
| `name` | String | read/write |
| `lore` | list&lt;String&gt; | read/write |
| `stats`, `tags` | — | custom-item namespaces — [Step 12](/1.3.0/guide/items-and-mobs) |

### `World`

| Property | Type | Access |
|---|---|---|
| `time` | Integer | read/write |
| `time_rate` | Integer | read/write |

### Event objects

Listed per event in the [event table](/1.3.0/guide/events#the-event-table). Later steps add
`Mob` ([Step 12](/1.3.0/guide/items-and-mobs)) and `Display` ([Step 13](/1.3.0/guide/modules))
values with tables of their own.

::: tip A closed whitelist is the feature
There is deliberately no reflection fallback exposing the whole server API to scripts.
If a property isn't in the table, it doesn't exist — which is what makes "did you mean
`latency`?" possible, keeps scripts working across server versions, and gives every
write a validated, thread-correct path.
:::
