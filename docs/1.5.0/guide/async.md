---
title: Async
---

<StepHeader>
a <code>/race</code> countdown that waits without freezing a tick — and three thread bugs the compiler refuses to compile.
</StepHeader>

Minecraft servers live and die by the tick: 20 per second, ~50 ms each, and everything
gameplay-visible happens on tick threads. A script that sleeps on a tick thread freezes
the world. SwoftLang's answer is compiler-checked async: code that waits runs on
background **virtual threads**, code that touches the world hops back to the tick
thread, and the compiler makes it impossible to get the two confused.

## The surface

Four constructs:

```swoftlang
async function countdown(target: Player, from: Integer) {   // 1. async function
    loop from times as i {
        send "<yellow>${from - i + 1}..." to target
        wait 1 seconds                                      // 2. wait
    }
    send "<lime>Go!" to target
}

command "race" {
    execute {
        spawn countdown(sender, 3)                          // 3. spawn
        send "countdown started" to sender
    }
}

Player {
    on_join {
        async {                                             // 4. async block
            wait 60 ticks
            send "<gold>Tip: type /help to get started" to player
        }
    }
}
```

`wait` takes `ticks`, `seconds`, or `millis`, with any integer expression for the amount.

## The coloring rules

Every region of code has a color — **sync** or **async** — decided entirely at compile
time:

| Region | Color |
|---|---|
| `execute { }` (command) | sync |
| `execute async { }` (command) | async |
| receiver method body (`on_join { }`) | sync |
| receiver method marked async (`on_join async { }`) | async |
| `async function` body | async |
| `async { }` block body | async |
| plain `function` body | sync — even when called from async code |

And the rules the checker enforces:

**1. `wait` needs async.** In sync code:

<!-- swoftc name=slow.sw expect=error -->

```swoftlang
command "slow" {
    execute {
        send "counting down..." to sender
        wait 3 seconds   // [!code error]
        send "done" to sender
    }
}
```

```txt
slow.sw:4:9: error: 'wait' is only allowed in async functions, 'execute async', or 'async { }' blocks
        wait 3 seconds
        ^
```

**2. Direct calls to async functions need async.** A direct call runs the async function
to completion on *your* thread — from sync code that would mean waiting on a tick
thread, so the compiler refuses:

<!-- swoftc name=heal.sw expect=error -->

```swoftlang
async function heal_later(p: Player) {
    wait 5 seconds
    set p.health to p.max_health
}

command "heal" {
    execute {
        if sender is a Player {
            heal_later(sender)   // [!code error]
        }
    }
}
```

```txt
heal.sw:9:13: error: 'heal_later' is an async function; call it with 'spawn heal_later(...)' or move this call into an async context
            heal_later(sender)
            ^
```

**3. `spawn` and `async { }` are legal in both colors.** They're fire-and-forget — a new
task starts, your code continues immediately, no value comes back.

**4. `cancel event` is banned in async regions** — the event has already dispatched by
the time async code runs ([why](/1.5.0/guide/events#cancelling-events)):

```txt
filter.sw:4:9: error: 'cancel event' must run before the handler goes async
        cancel event
        ^
```

That's the entire model. Sync functions stay callable from anywhere; only
genuinely-waiting code needs the `async` keyword.

The same `wait`, mapped from Skript:

<MappedCompare>
<MappedPair label="a delayed heal">
<template #skript>

```skript
command /heal:
    trigger:
        send "&7Healing in 5 seconds..." to player
        wait 5 seconds
        # everything below now runs 5s later — the trigger
        # silently became delayed; cancelling the event or
        # relying on "still on the event thread" breaks
        heal player
        send "&aHealed!" to player
```

</template>
<template #swoftlang>

```swoftlang
command "heal" {
    execute async {
        send "<gray>Healing in 5 seconds..." to sender
        wait 5 seconds
        if sender is a Player {
            set sender.health to sender.max_health
        }
        send "<green>Healed!" to sender
    }
}
```

</template>
<template #note>

The spelling is identical — `wait 5 seconds` — but in Skript, `wait` silently turns the
rest of the trigger into delayed code and nothing warns you. In SwoftLang, `wait` is
only legal in code that is *declared* async, it parks a virtual thread instead of
anything tick-related, and using it in sync code is a compile error. The declaration is
the documentation.

</template>
</MappedPair>
</MappedCompare>

## Getting values back

Inside async code, calling an async function directly is sequential and returns its
value — it reads exactly like sync code:

```swoftlang
async function fetch_bonus(base: Integer) {
    wait 100 millis
    return base * 2
}

command "bonus" {
    execute async {
        send "crunching..." to sender
        set b to fetch_bonus(50)
        send "your bonus is ${b}" to sender
    }
}
```

No callbacks, no futures, no `.then`. The task parks at each `wait` and the story reads
top to bottom.

`spawn`, by contrast, never returns a value — it's for kicking off independent work.
Argument expressions are evaluated in the *parent* before the task detaches, so
`spawn farewell(sender.name)` captures the name at spawn time.

## What runs where

You don't manage any of this, but knowing it explains the rules:

- **Sync bodies** run inline on the tick thread, exactly like a hand-written listener —
  zero overhead, and why `wait` is banned there.
- **Async bodies** each get a virtual thread; thousands of concurrently-waiting tasks
  cost kilobytes each.
- **`wait n ticks`** resumes your task aligned to the tick boundary; `seconds`/`millis`
  are plain sleeps.
- **Touching the world** — teleporting, setting health, changing held items — must
  happen on the tick thread. Every [property](/1.5.0/guide/properties#threading) knows its
  thread policy; tick-only writes from async code are automatically funneled to the next
  tick while your task parks. So `set p.health to 0` in an async task is correct as
  written — the runtime does the thread hop, not you.

## Scope snapshots

A spawned task gets a **shallow snapshot** of the parent's variables. Bindings are
copied; objects are shared:

- `set x to 5` in the task — invisible to the parent.
- `set p.health to 5` in the task — very visible. There's only one player.

Function values are the one exception to "objects are shared": a lambda crossing a task
boundary is rebound over a snapshot of its captured environment, so calling it inside
the task never writes back into the parent's variables.

## `halt` in a task

`halt` kills the **current task only** — a spawned task halting never affects the parent
script or sibling tasks. An uncaught script error likewise kills just its own task, with
a log line citing script and line number.

## Stale players

A task that waits can outlive its player:

```swoftlang
async function delayed_reward(p: Player) {
    wait 30 seconds
    if p.online {
        set p.health to p.max_health
        send "<lime>Reward!" to p
    }
}

command "reward" {
    execute {
        spawn delayed_reward(sender)
    }
}
```

`p.online` is the idiomatic guard. As defense in depth, tick-dispatched writes to an
offline player are silently dropped rather than corrupting anything — but write the
guard; your intent should live in the script.

::: tip Lifecycle
All tasks are tracked. On script reload or server shutdown, every running task is
cancelled cleanly — a `wait 10 minutes` won't hold your server open.
:::
