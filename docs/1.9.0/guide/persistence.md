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

Player {
    on_join {
        set total_joins to total_joins + 1
        broadcast "<green>${player.name} is join #${total_joins}"
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

A live `Entity` never persists — it's a runtime connection, not a value — so
`persistent mobs: List<Entity>` is a compile error, with the fix in the hint: persist a
respawnable snapshot instead. A **`Player`** is the exception: it has a stable uuid, so it
persists *as a value* — stored by that uuid and thawed back to the live player on load (or
quietly dropped if they've never been seen). See
[Players as persistent values](#player-values) below. The one shape still rejected is a
*bare* top-level `persistent p: Player`: with no `none` or default to fall back to, there's
nowhere for an unresolvable uuid to land — wrap it in an `Optional<Player>` (or a `list`,
`map`, or struct field) and it's fine.

## Keyed variables: `for Player`

Most real state is per-player. Add `for Player` and the variable becomes a keyed store,
one value per subject:

```swoftlang
persistent kills for Player: Integer = 0
persistent last_seen for Player: String = "never"

Player {
    on_join {
        send "kills on record: ${kills for player}" to player
        set last_seen for player to "today"
    }
}
```

Access is `kills for <expr>`, where the expression must typecheck to the subject type.
Assignment mirrors it: `set kills for player to ...`.

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
persistent warps: Map<String, Location> = new_map()

persistent home for Player: Location = location(0, 64, 0)
persistent last_death for Player: Optional<Location> = none
persistent knockback for Player: Vec = velocity(0, 0.4, 0)
persistent starter for Player: Item = item("stick")
persistent kit for Player: List<Item> = []
persistent waypoints for Player: List<Location> = []
persistent stash for Player: Map<String, Item> = new_map()
```

`Location`, `Vec`, and `Item` freeze to the backend as their NBT — coordinates, the
velocity components, the full item stack with name, lore, and tags — and thaw back into
the same live value on load. Every declaration still needs a present default; the one
exception is an `optional` type, which may legitimately default to `none` (`last_death`
above starts empty and stays empty until someone dies).

Map keys may be `String`, `Integer`, or `Player` (a `Player` key is stored by uuid), and
map *values*, list elements, and the target of an `optional` must themselves be a
persistable value type — or a `Player`, which persists by uuid (below). So both
`Map<String, Item>` and `Map<String, Player>` are fine; only `Map<String, Entity>` is the
live-handle error, because a bare `Entity` has no stable identity to store.

### Players as persistent values {#player-values}

A `Player` is stored by its **uuid**, so it counts as a persistable value anywhere a value
type is allowed *except* on its own at the top level (a bare `persistent p: Player` has no
fallback for an unresolvable uuid — use `Optional<Player>`). Inside a `list`, an
`optional`, as a `map` *value*, or as a struct field, it just works:

```swoftlang
persistent party for Player: List<Player> = []
persistent rival for Player: Optional<Player> = none
persistent duel_partner: Map<String, Player> = new_map()

struct Bout {
    challenger: Player
    opponent: Optional<Player>
    round: Integer = 1
}

persistent bouts: Map<String, Bout> = new_map()
```

On load each uuid is **resolved or culled**: an online player thaws back to the live
`Player`, and a uuid whose player isn't reachable is dropped from the `list`/`map` (or an
`optional` reads back `none`). You store durable membership — a party, a rivalry, a
bracket — and read live handles back out, with the "have they logged in this session?"
bookkeeping handled for you.

### Save a home, save a kit

Put the rich types to work: a `/sethome` that remembers a `Location` and a `/savekit`
that snapshots an `Item` list. Because reads are total, `/home` only has to narrow the
`optional` — there's no "have they set one?" bookkeeping beyond the `exists` check.

```swoftlang
storage {
    backend: sqlite "data/homes.db"
    flush: every 10 seconds
}

persistent home for Player: Optional<Location> = none
persistent kit for Player: List<Item> = []

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

The whole `Item` — enchantments, custom name, [custom-item](/1.9.0/reference/items) identity —
survives the round trip, so a saved kit comes back exactly as it went in.

### Persistent structs

A [struct](/1.9.0/reference/structs) whose fields are *all* persistable types is itself
persistable — so a whole record travels as one value instead of a scatter of parallel
maps. It serializes to a JSON object of its fields and thaws back on boot, reads stay total
against the declared default, and the same live-handle rule bites: a struct with an
`Entity`/`Mob` field can't be persistent, and the checker names the field.

```swoftlang
struct Guild {
    name: String
    level: Integer = 1
    bank: Map<String, Integer>
    home: Optional<Location>
}

persistent guilds: Map<String, Guild> = new_map()
```

Storing a struct persistently also makes any [`@EventReceiver`](/1.9.0/reference/structs#reactive)
field on it *live* — reachability from a persistent root is what activates a reactive
struct's handlers. See [Structs → persistent state](/1.9.0/reference/structs#persistent) for the
full treatment.

## Schema migration {#schema-migration}

Persistent structs are records on disk, and records drift: you rename a field, split one
into two, change a type, add a column. The core guarantee is that **loading never crashes on
drift** — a stored row that doesn't match today's struct is reconciled on read, never
rejected. There are two levels, and most changes need only the first.

### Additive & subtractive auto-heal (no ceremony)

Add a field or remove one and *do nothing else*. On load, every stored row is healed against
the current struct:

- **A field the row is missing** (you just added it) fills from the field's declared
  default.
- **A field the row still has but the struct dropped** is simply ignored.

Nothing to declare, nothing to version:

<!-- swoftc name=profile.sw -->

```swoftlang
// v1 stored { name, title }. This is v2: `nickname` is new (old rows heal to
// "friend"), and the old `title` column is gone (dropped on load). No schema
// bump, no migrate block — reads stay total and nothing crashes.
struct Profile {
    name: String
    nickname: String = "friend"
    joins: Integer = 0
}

persistent profile for Player: Profile = Profile { name: "" }
```

This is the same [totality](/1.9.0/reference/structs) that makes every persistent read return a
value: a healed row is indistinguishable from one written fresh.

### Explicit migration: `schema` + `migrate to`

Auto-heal can't guess a **rename**, a **type change**, or a **backfill from another field** —
that's a value transformation, not a fill-with-default. For those, version the struct with
`schema: N` and describe each hop with a `migrate to N { }` block.

Start from a v1 struct:

```swoftlang
struct Guild {
    title: String
    coins: Integer = 0
}

persistent guilds: Map<String, Guild> = new_map()
```

Evolve it — rename `title` to `name`, add a `tag`, widen `coins` to a `balance: Double`, add
a `motd` — and spell out how an old row becomes a new one:

<!-- swoftc name=guild.sw -->

```swoftlang
struct Guild {
    schema: 3

    name: String
    tag: String = ""
    balance: Double = 0.0
    motd: String = ""

    // v1 -> v2: `title` was renamed to `name`; `tag` is brand new.
    migrate to 2 {
        set name to raw["title"] otherwise "Unnamed"
        set tag to ""
    }

    // v2 -> v3: the old whole-number `coins` value flows in through `raw`
    // (typed Any) and lands in the Double `balance`; seed `motd` from `name`.
    migrate to 3 {
        set balance to raw["coins"] otherwise 0.0
        set motd to "Welcome to ${name}"
    }
}

persistent guilds: Map<String, Guild> = new_map()
```

The pieces:

- **`schema: N`** — the struct's current version (default `1`). Every stored row is tagged
  with the schema it was written under; a row tagged older than `N` is upgraded on load.
- **`migrate to N { }`** — the upgrade *to* version `N`, run when a row below `N` is loaded.
  Blocks run in ascending order, so a v1 row loaded against `schema: 3` runs `migrate to 2`
  then `migrate to 3`. `N` must be between `2` and the declared `schema` (version 1 is the
  initial schema — nothing migrates *to* it).
- **`raw["oldName"]`** — inside a migrate block, `raw` is a `Map<String, Any>` of the row's
  *previously stored* fields, so you can read columns that no longer exist on the struct
  (like `title` and `coins` above). `otherwise <fallback>` supplies a value when the key is
  absent, keeping the read total.
- **The block assigns the struct's current fields.** Each `set` targets a field of the
  struct (assigning anything else is a compile error), and the value must fit that field's
  type — the migration is typechecked like any other code.

The checker enforces the shape: a `migrate to 1` (or `to 0`), a target above `schema`, a
duplicate `migrate to N`, or a `set` to an unknown field are all compile errors, so a
migration that couldn't run can't ship. And because schema/migrate only make sense on data
that reaches disk, they're rejected on a struct that isn't persistent-capable (name the
offending non-serializable field).

::: tip Which level do I need?
Adding or removing a field → nothing, auto-heal covers it. Renaming, changing a type, or
computing one field from another → bump `schema` and add a `migrate to`. Either way, a live
server loading old data never crashes on the mismatch.
:::

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
for missing values by hand, which is exactly what [Step 07](/1.9.0/guide/options) abolished.
:::
