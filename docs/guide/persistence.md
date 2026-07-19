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
- a **type** — one of `String`, `Integer`, `Double`, `Boolean`,
- a **default** — required, and it's what makes reads *total*: a value that has never
  been written reads as the default, so `total_joins` is always a plain `Integer`, never
  an `optional`. No migration dance, no "was it initialized" checks.

Only scalar types persist. `Player`, `Location`, and `Item` are live game objects that
can't meaningfully be frozen to disk — declaring one is a compile error with the fix in
the hint: store primitive fields instead (the UUID string, the coordinates as doubles,
the material name).

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
