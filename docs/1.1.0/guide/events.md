---
title: Events
---

<StepHeader>
a join greeter and a chat filter that vetoes messages — with the compiler proving the veto can actually work.
</StepHeader>

An `event` block runs when something happens on the server. Each event is declared by its
real name; the compiler rejects a name it doesn't know, so a handler that would never
fire is a compile error:

<!-- swoftc name=sneeze.sw expect=error -->

```swoftlang
event PlayerSneeze {
    execute {
        send "bless you" to event.player
    }
}
```

```txt
sneeze.sw:1:1: error: unknown event 'PlayerSneeze'
event PlayerSneeze {
^
```

Inside a handler, `event` is the event object, carrying a fixed, compile-time-checked
set of properties. The two shapes you'll write most map straight from Skript:

<MappedCompare>
<MappedPair label="join greeter">
<template #skript>

```skript
on join:
    broadcast "&e%player% joined the game"
    send "&aWelcome, %player%!" to player
```

</template>
<template #swoftlang>

```swoftlang
event PlayerJoin {
    execute {
        broadcast "<yellow>${event.player.name} joined the game"
        send "<green>Welcome, ${event.player.name}!" to event.player
    }
}
```

</template>
<template #note>

`on join:` becomes `event PlayerJoin { }`, and event data hangs off a typed `event`
value. `event.player.name` is checked against a real property table at compile time —
misspell it and the compiler suggests the fix ([Step 08](/1.1.0/guide/properties)).
`broadcast "..."` is shorthand for `send "..." to all`.

</template>
</MappedPair>
<MappedPair label="chat filter">
<template #skript>

```skript
on chat:
    if message contains "badword":
        cancel event
        send "&cWatch your language" to player
```

</template>
<template #swoftlang>

```swoftlang
event PlayerChat {
    execute {
        if event.message contains "badword" {
            cancel event
            send "<red>Watch your language" to event.player
        }
    }
}
```

</template>
<template #note>

Nearly word-for-word — `contains` and `cancel event` exist in both. The difference is
what the compiler knows: SwoftLang only allows `cancel event` on events that are
actually cancellable, and only *before* the handler goes async (both enforced below).

</template>
</MappedPair>
</MappedCompare>

## Rewriting event data

Some event properties are writable. Assigning to `event.message` rewrites the chat line
before anyone sees it:

```swoftlang
event PlayerChat {
    priority: 0

    execute {
        if event.message contains "badword" {
            send "<red>Watch your language." to event.player
            cancel event
            halt
        }
        set event.message to "[chat] ${event.message}"
    }
}
```

Property writes go through the same checked table as reads — the compiler knows
`message` is writable and `player` is not.

::: tip Shortcut aliases
For ergonomics, each event also binds its headline data as bare variables — `player` and
`message` in a chat handler, `player` and `name` in a join handler. `event.` is the
canonical spelling; the aliases are sugar.
:::

## Priorities

`priority` orders handlers for the same event: **lower runs first**. A priority-0 filter
sees the raw message; a priority-10 logger sees whatever the filter left behind.
Handlers with no `priority` default to 0. (The ordering guarantee is for synchronous
handlers — once a handler detaches async work, that work interleaves arbitrarily; see
[Step 09](/1.1.0/guide/async).)

## The event table

The events the compiler recognizes, and the properties each binds on `event`. Any
`event.player` chains on into the full [property tables](/1.1.0/guide/properties#the-property-tables).

| Event | Cancellable | Properties on `event` |
|---|---|---|
| `PlayerChat` | yes | `player` (ro), `message` (rw), `cancelled` (rw) |
| `PlayerJoin` | no | `player` (ro), `first_spawn` (ro), `world` (ro) |
| `PlayerUseItem` | yes | `player` (ro), `item` (ro), `custom_id` (ro, optional), `cancelled` (rw) |
| `BlockBreak` | yes | `player` (ro), `block` (ro), `location` (ro), `cancelled` (rw) |
| `BlockPlace` | yes | `player` (ro), `block` (ro), `location` (ro), `cancelled` (rw) |
| `MobSpawn` | no | `mob` (ro) |
| `MobDeath` | no | `mob` (ro), `killer` (ro, optional) |
| `MobDamage` | yes | `mob` (ro), `damage` (rw), `cancelled` (rw) |
| `TpsChange` | no | `past` (ro), `current` (ro) |
| `ServerPing` | no | `motd` (rw), `online` (rw), `max` (rw) |

The mob and item events come alive in [Step 12](/1.1.0/guide/items-and-mobs); `ServerPing`
powers dynamic MOTDs in [Step 16](/1.1.0/guide/ship-it#a-dynamic-motd).

## Cancelling events

`cancel event` stops the underlying server event — a cancelled chat message is never
broadcast. Two rules, both enforced at compile time.

**1. Only cancellable events can be cancelled.** A join has already happened; there is
nothing to veto:

<!-- swoftc name=join.sw expect=error -->

```swoftlang
event PlayerJoin {
    execute {
        cancel event
    }
}
```

```txt
join.sw:3:9: error: event 'PlayerJoin' is not cancellable
        cancel event
        ^
```

**2. Cancellation is sync-only.** The server reads the cancelled flag the moment your
listener returns. Async code runs *after* that — by then the chat message has already
gone out, and cancelling would be a silent no-op. SwoftLang makes it a compile error
instead ([the async model](/1.1.0/guide/async#the-coloring-rules) is Step 09):

<!-- swoftc name=filter.sw expect=error -->

```swoftlang
event PlayerChat {
    execute async {
        wait 1 ticks
        cancel event
    }
}
```

```txt
filter.sw:4:9: error: 'cancel event' must run before the handler goes async
        cancel event
        ^
```

The canonical pattern: decide and cancel synchronously, then hand slow work to a task:

```swoftlang
event PlayerChat {
    execute {
        if event.message contains "spoiler" {
            cancel event
            spawn warn_later(event.player)
        }
    }
}

async function warn_later(p: Player) {
    wait 1 seconds
    send "<red>No spoilers in chat!" to p
}
```

The cancel lands while the listener still holds the event; the warning arrives a second
later from a background task. Next up: the variables these handlers have been quietly
using.
