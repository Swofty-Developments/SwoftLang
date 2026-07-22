---
title: Events
---

<StepHeader>
a join greeter and a chat filter that vetoes messages — with the compiler proving the veto can actually work.
</StepHeader>

Things that happen on the server are handled by **receivers** — Capitalized blocks, one per
subject, whose methods run when something happens to that subject. Everything a player can
do lives in a `Player { }` block; each method is a specific event:

```swoftlang
Player {
    on_join {
        broadcast "<yellow>${player.name} joined the game"
    }
}
```

Inside a method the subject is a bare variable named after its type — here `player`, the
one who just joined. Each method binds a fixed set of variables, settled at compile time,
so a handler that reaches for data the event never binds is a compile error:

<!-- swoftc name=badjoin.sw expect=error -->

```swoftlang
Player {
    on_join {
        send "<red>Under attack!" to attacker    // [!code error]
    }
}
```

```txt
badjoin.sw:3:38: error: variable 'attacker' is never assigned
        send "<red>Under attack!" to attacker
                                     ^
```

The two shapes you'll write most map straight from Skript:

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
Player {
    on_join {
        broadcast "<yellow>${player.name} joined the game"
        send "<green>Welcome, ${player.name}!" to player
    }
}
```

</template>
<template #note>

`on join:` becomes `Player { on_join { } }`, and the player is the bare variable `player`.
`player.name` is checked against a real property table at compile time — misspell it and
the compiler suggests the fix ([Step 08](/1.5.0/guide/properties)). `broadcast "..."` is
shorthand for `send "..." to all`.

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
Player {
    on_chat {
        if message contains "badword" {
            cancel event
            send "<red>Watch your language" to player
        }
    }
}
```

</template>
<template #note>

`on chat:` becomes `Player { on_chat { } }` — the chat text is the bound variable
`message`, and `player` is the sender. `contains` and `cancel event` exist in both.
The difference is what the compiler knows: SwoftLang only allows `cancel event` on events
that are actually cancellable, and only *before* the handler goes async (both enforced
below).

</template>
</MappedPair>
</MappedCompare>

## Rewriting event data

Some bound variables are writable — assigning to them rewrites the event before anyone
sees it. Reassigning `message` rewrites the chat line:

```swoftlang
Player {
    on_chat {
        if message contains "badword" {
            send "<red>Watch your language." to player
            cancel event
            halt
        }
        set message to "[chat] ${message}"
    }
}
```

Which bound variables are writable is fixed per method (the
[receiver tables](/1.5.0/reference/events) mark them `rw`) — `message` is writable, `player` is
not.

::: tip The subject is a bare variable
Every method binds what the block is about to a variable named after its type — `player` in
a `Player` method, `mob` in a `Mob` method, `block` in a `Block` method. The rest of the
event's data is bound alongside it as bare variables.
:::

## The receiver tables {#the-event-table}

The full catalog — every receiver, every method, and the data each binds — lives in the
[Receivers & Events reference](/1.5.0/reference/events). The headline `Player` methods this guide
leans on (`player` is always bound; the extra bound variables are listed):

| Method | Cancellable | Bound variables |
|---|---|---|
| `on_join` | no | — |
| `on_chat` | yes | `message` (String, rw) |
| `on_move` | yes | `new_position` (Location, rw) |
| `on_death` | no | `death_text` (rw), `chat_message` (rw) |
| `on_command` | yes | `command` (String, rw) |
| `on_break_block` | yes | `block`, `location`, `face` |

Custom [items and mobs](/1.5.0/guide/items-and-mobs) get their own methods on top of the base
receivers; `Server { on_list_ping }` powers dynamic MOTDs in
[Step 16](/1.5.0/guide/ship-it#a-dynamic-motd).

## Cancelling events

`cancel event` stops the underlying server event — a cancelled chat message is never
broadcast. Two rules, both enforced at compile time.

**1. Only cancellable events can be cancelled.** A join has already happened; there is
nothing to veto:

<!-- swoftc name=join.sw expect=error -->

```swoftlang
Player {
    on_join {
        cancel event
    }
}
```

```txt
join.sw:3:9: error: event 'on_join' is not cancellable
        cancel event
        ^
```

**2. Cancellation is sync-only.** The server reads the cancelled flag the moment your
method returns. Async code runs *after* that — by then the chat message has already gone
out, and cancelling would be a silent no-op. SwoftLang makes it a compile error instead
([the async model](/1.5.0/guide/async#the-coloring-rules) is Step 09):

<!-- swoftc name=filter.sw expect=error -->

```swoftlang
Player {
    on_chat async {
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
Player {
    on_chat {
        if message contains "spoiler" {
            cancel event
            spawn warn_later(player)
        }
    }
}

async function warn_later(p: Player) {
    wait 1 seconds
    send "<red>No spoilers in chat!" to p
}
```

The cancel lands while the method still holds the event; the warning arrives a second later
from a background task. Next up: the variables these handlers have been quietly using.
