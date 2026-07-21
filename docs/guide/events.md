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
    on_join() {
        broadcast "<yellow>${this.name} joined the game"
    }
}
```

Inside a method, `this` is the subject — here, the player who joined. Each method has a
fixed name and a fixed set of parameters, both checked at compile time, so a handler that
binds the wrong data is a compile error:

<!-- swoftc name=badchat.sw expect=error -->

```swoftlang
Player {
    on_chat() {            // [!code error]
        broadcast "hi"
    }
}
```

```txt
badchat.sw:2:5: error: Player method 'on_chat' expects 1 parameter (message: String), got 0
    on_chat() {
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
    on_join() {
        broadcast "<yellow>${this.name} joined the game"
        send "<green>Welcome, ${this.name}!" to this
    }
}
```

</template>
<template #note>

`on join:` becomes `Player { on_join() { } }`, and the player is `this`. `this.name` is
checked against a real property table at compile time — misspell it and the compiler
suggests the fix ([Step 08](/guide/properties)). `broadcast "..."` is shorthand for
`send "..." to all`.

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
    on_chat(message) {
        if message contains "badword" {
            cancel event
            send "<red>Watch your language" to this
        }
    }
}
```

</template>
<template #note>

`on chat:` becomes `Player { on_chat(message) { } }` — the chat text arrives as the
`message` parameter, `this` is the sender. `contains` and `cancel event` exist in both.
The difference is what the compiler knows: SwoftLang only allows `cancel event` on events
that are actually cancellable, and only *before* the handler goes async (both enforced
below).

</template>
</MappedPair>
</MappedCompare>

## Rewriting event data

Some method parameters are writable — assigning to them rewrites the event before anyone
sees it. Reassigning `message` rewrites the chat line:

```swoftlang
Player {
    on_chat(message) {
        if message contains "badword" {
            send "<red>Watch your language." to this
            cancel event
            halt
        }
        set message to "[chat] ${message}"
    }
}
```

Which parameters are writable is fixed per method (the [receiver tables](/reference/events)
mark them `rw`) — `message` is writable, `this` is not.

::: tip `this` is the subject
Every method binds `this` to what the block is about — the player in a `Player` method, the
mob in a `Mob` method, the block in a `Block` method. Reach the rest of the event's data
through the method's parameters.
:::

## The receiver tables {#the-event-table}

The full catalog — every receiver, every method, and the data each binds — lives in the
[Receivers & Events reference](/reference/events). The headline `Player` methods this guide
leans on:

| Method | Cancellable | Parameters |
|---|---|---|
| `on_join()` | no | — |
| `on_chat(message)` | yes | `message` (String, rw) |
| `on_move(new_position)` | yes | `new_position` (Location, rw) |
| `on_death(death_text, chat_message)` | no | `death_text` (rw), `chat_message` (rw) |
| `on_command(command)` | yes | `command` (String, rw) |
| `on_break_block(block, location, face)` | yes | `block`, `location`, `face` |

Custom [items and mobs](/guide/items-and-mobs) get their own methods on top of the base
receivers; `Server { on_list_ping(status) }` powers dynamic MOTDs in
[Step 16](/guide/ship-it#a-dynamic-motd).

## Cancelling events

`cancel event` stops the underlying server event — a cancelled chat message is never
broadcast. Two rules, both enforced at compile time.

**1. Only cancellable events can be cancelled.** A join has already happened; there is
nothing to veto:

<!-- swoftc name=join.sw expect=error -->

```swoftlang
Player {
    on_join() {
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
([the async model](/guide/async#the-coloring-rules) is Step 09):

<!-- swoftc name=filter.sw expect=error -->

```swoftlang
Player {
    on_chat(message) async {
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
    on_chat(message) {
        if message contains "spoiler" {
            cancel event
            spawn warn_later(this)
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
