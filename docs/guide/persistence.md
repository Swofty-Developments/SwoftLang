---
title: Persistence
---

<StepHeader>
a <code>/stats</code> command whose counters survive restarts — declared types, declared defaults, backend of your choice.
</StepHeader>

Everything in the course so far evaporates on restart — variables live in memory, and a
server reboot wipes them. **Persistent variables** survive: declare one with
`persistent`, read and write it like any other variable, and the runtime keeps it in a
storage backend of your choice.

If you're coming from Skript, this is the `{kills::%uuid of player%}` pattern with the
bookkeeping promoted into a declaration:

<MappedCompare>
<MappedPair label="per-player kill counter">
<template #skript>

```skript
# {kills::...} autosaves to variables.csv; no type,
# no default — an unwritten value reads as <none>
command /addkill:
    trigger:
        add 1 to {kills::%uuid of player%}
        send "&7Lifetime kills: %{kills::%uuid of player%}%" to player
```

</template>
<template #swoftlang>

```swoftlang
persistent kills for Player: Integer = 0

command "addkill" {
    execute {
        if sender is a Player {
            set kills for sender to (kills for sender) + 1
            send "<gray>Lifetime kills: ${kills for sender}" to sender
        }
    }
}
```

</template>
<template #note>

The type and default are part of the declaration, so a never-written value reads as `0`
(never `<none>`), and the key is the player's UUID automatically — state follows the
player across name changes. Backends are configured in one `storage` block below, not
per-variable regex patterns in a config file.

</template>
</MappedPair>
</MappedCompare>

## Declaring persistent variables

```swoftlang
persistent total_joins: Integer = 0

event PlayerJoin {
    execute {
        set total_joins to total_joins + 1
        broadcast "<green>${event.player.name} is join #${total_joins}"
    }
}
```

A `persistent` declaration sits at the top level of a script, like a function. It needs
three things:

- a **name** — read and written exactly like a variable,
- a **type** — a value type that serializes cleanly: the scalars `String`, `Integer`,
  `Double`, `Boolean`, the game values `Location`, `Vec`, `Item`, or a `list`/`map`/`optional`
  of those (see [Rich value types](#rich-value-types)),
- a **default** — required, and it's what makes reads *total*: a value that has never
  been written reads as the default, so `total_joins` is always a plain `Integer`, never
  an `optional`. No migration dance, no "was it initialized" checks.

Live handles never persist. A `Player` (or any `Entity`) is a runtime connection, not a
value — declaring `persistent x: Player` is a compile error with the fix in the hint:
persist the uuid `String` or a respawnable snapshot instead. The rule bites through
collections too, so `list<Player>` and `map<String, Entity>` are rejected the same way.

## Keyed variables: `for Player`

Most real state is per-player. Add `for Player` and the variable becomes a keyed store,
one value per subject:

```swoftlang
persistent kills for Player: Integer = 0
persistent last_seen for Player: String = "never"

event PlayerJoin {
    execute {
        send "kills on record: ${kills for event.player}" to event.player
        set last_seen for event.player to "today"
    }
}
```

Access is `kills for <expr>`, where the expression must typecheck to the subject type.
Assignment mirrors it: `set kills for event.player to ...`.

The checker keeps the two shapes apart — bare access to a keyed variable doesn't
compile:

<!-- swoftc name=keyed.sw expect=error -->

```swoftlang
persistent kills for Player: Integer = 0

command "stats" {
    execute {
        send "kills: ${kills}" to sender   // [!code error]
    }
}
```

```txt
keyed.sw:5:14: error: 'kills' is keyed by Player — use 'kills for <player>'
        send "kills: ${kills}" to sender
             ^
```

Wrong subject types and wrong value types are caught the same way. And because a
persistent name is a script-wide global, the checker refuses to let *anything* shadow it
— a command argument, function parameter, or loop binder reusing the name is a compile
error (`argument 'kills' shadows the persistent variable 'kills' — rename one of
them`), as is a persistent that collides with a function, builtin, or reserved binding
like `sender`. A shadowed counter that silently reads a local instead of the store is
exactly the bug class persistence exists to kill.

## Rich value types {#rich-value-types}

Persistence isn't limited to counters. Anything that has a *total* serialization —
scalars, the game values `Location`, `Vec`, and `Item`, and any `list`, `map`, or
`optional` built from them — can be a persistent variable, keyed or not:

```swoftlang
persistent spawn: Location = location(0, 100, 0)
persistent warps: map<String, Location> = new_map()

persistent home for Player: Location = location(0, 64, 0)
persistent last_death for Player: optional<Location> = none
persistent knockback for Player: Vec = velocity(0, 0.4, 0)
persistent starter for Player: Item = item("stick")
persistent kit for Player: list<Item> = []
persistent waypoints for Player: list<Location> = []
persistent stash for Player: map<String, Item> = new_map()
```

`Location`, `Vec`, and `Item` freeze to the backend as their NBT — coordinates, the
velocity components, the full item stack with name, lore, and tags — and thaw back into
the same live value on load. Every declaration still needs a present default; the one
exception is an `optional` type, which may legitimately default to `none` (`last_death`
above starts empty and stays empty until someone dies).

Map keys may be `String`, `Integer`, or `Player` (a `Player` key is stored by uuid), and
map *values*, list elements, and the target of an `optional` must themselves be a
persistable value type. So `map<String, Item>` is fine; `map<String, Player>` is the
live-handle error again.

### Save a home, save a kit

Put the rich types to work: a `/sethome` that remembers a `Location` and a `/savekit`
that snapshots an `Item` list. Because reads are total, `/home` only has to narrow the
`optional` — there's no "have they set one?" bookkeeping beyond the `exists` check.

```swoftlang
storage {
    backend: sqlite "data/homes.db"
    flush: every 10 seconds
}

persistent home for Player: optional<Location> = none
persistent kit for Player: list<Item> = []

command "sethome" {
    description: "Save your current spot as home"
    execute {
        if sender is a Player {
            set home for sender to sender.location
            send "<green>Home saved." to sender
        }
    }
}

command "home" {
    description: "Teleport to your saved home"
    execute {
        if sender is a Player {
            set spot to home for sender
            if spot exists {
                teleport sender to spot
                send "<gray>Welcome home." to sender
            } else {
                send "<red>You haven't set a home yet." to sender
            }
        }
    }
}

command "savekit" {
    description: "Remember your held item as your kit"
    execute {
        if sender is a Player {
            set kit for sender to [sender.held_item]
            send "<green>Kit saved (${length(kit for sender)} items)." to sender
        }
    }
}

command "loadkit" {
    execute {
        if sender is a Player {
            loop kit for sender as piece {
                set sender.held_item to piece
            }
        }
    }
}
```

The whole `Item` — enchantments, custom name, [custom-item](/reference/items) identity —
survives the round trip, so a saved kit comes back exactly as it went in.

## The `storage` block

One optional `storage` block (at most one across all scripts, like `server { }`) picks
the backend:

```swoftlang
storage {
    backend: files "data/swoftlang"
    flush: every 30 seconds
}
```

With no block at all, you get the `files` backend in `swoftlang-data/` — persistence
works out of the box.

### Backends

::: code-group

```swoftlang [files]
storage {
    backend: files "data/swoftlang"
}
```

```swoftlang [sqlite]
storage {
    backend: sqlite "data/swoftlang.db"
}
```

```swoftlang [mysql]
storage {
    backend: mysql {
        host: "localhost"
        port: 3306
        database: "mc"
        user: "root"
        password: "hunter2"
    }
}
```

```swoftlang [mongodb]
storage {
    backend: mongodb "mongodb://localhost:27017/swoftlang"
}
```

:::

| Backend | Storage shape | Reach for it when |
|---|---|---|
| `files` | one JSON file per variable, atomic tmp-and-move writes | default; single server, zero setup, human-readable data |
| `sqlite` | one table `swoft_persist(var, key, value)` in a local file | lots of keys, still zero infrastructure |
| `mysql` | same table shape, remote | state shared with other tools, or backed up centrally |
| `mongodb` | one `swoft_persist` collection of `{var, key, value}` docs | you already run Mongo |

Scripts are identical across backends — only the `storage` block changes.

## Write-behind: what actually happens when

Persistent reads and writes are **always in-memory**:

- At startup, the runtime loads every declared variable's data into a cache (values are
  coerced to the declared type; corrupt or missing entries fall back to the default with
  a warning).
- `set total_joins to ...` writes the cache and marks the entry dirty. Cost: a map
  write. It never blocks on IO, never touches the tick thread's time budget.
- A background flusher writes dirty entries to the backend on the `flush` cadence —
  default `every 30 seconds`.
- A clean shutdown flushes everything.

The trade is explicit: scripts stay fast and IO never stalls a tick, but a hard crash
(power loss, `kill -9`) can lose up to one flush window of writes. Tighten `flush:
every 5 seconds` if that window matters more than write volume. For transactional
guarantees you want an external database via its own tooling, not a game scripting
runtime.

## The payoff

```swoftlang
storage {
    backend: sqlite "data/stats.db"
    flush: every 10 seconds
}

persistent total_deaths: Integer = 0
persistent kills for Player: Integer = 0
persistent best_streak for Player: Integer = 0

command "stats" {
    description: "Your lifetime stats"

    execute {
        if sender is a Player {
            send "<gold>kills: ${kills for sender}" to sender
            send "<gold>best streak: ${best_streak for sender}" to sender
            send "<gray>server-wide deaths: ${format_number(total_deaths)}" to sender
        }
    }
}
```

Restart the server, `/stats` still knows.

::: tip Why not just autosave regular variables?
Persistence is opt-in and declared because the declaration *is* the schema: the type and
default written next to the name are what make every read total and every stored value
validated on load. A "save everything" approach has neither — you'd be back to checking
for missing values by hand, which is exactly what [Step 07](/guide/options) abolished.
:::
